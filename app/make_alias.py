from os import path, makedirs
import requests
from json import loads
from constants import encrypted_token_path, encrypted_alias_path, alias_token_url, username
import decrypt
import encrypt 
import make_user_tkn

# First, open encrypted xnat token, decrypt it,
# then retrieve alias token from XNAT API,
# then encrypt and store that alias token

#............................................................
#   AUTHENTICATION: alias k:v tokens, then jsession token
#............................................................
# TODO: if login error, go back and run xnat-auth

def make_alias():
    (xnat_username, xnat_password) = [None, None]   # init variables
    # Decrypt user token, generate new one if there's an error
    if path.exists(encrypted_token_path):
        print("Located token file. Decrypting...")
        try:
            (xnat_username, xnat_password) = decrypt.decrypt(encrypted_token_path)
        except:
            print("There was a problem decrypting the token file. Let's try making a new one.")
            make_user_tkn.make_user_token()
            (xnat_username, xnat_password) = decrypt.decrypt(encrypted_token_path)
    else:
        print("Couldn't locate a user token file. That's okay, we can make a new one now.")
        make_user_tkn.make_user_token()
        (xnat_username, xnat_password) = decrypt.decrypt(encrypted_token_path)

    # Inititalize requests' session object
    session = requests.Session()    # Stores all the info we need for our session
    if xnat_username:
        session.auth = (xnat_username, xnat_password)
        try:
            alias_response = session.get(alias_token_url) # Gets entire response header object
            alias_response.raise_for_status()
            alias_resp_text = alias_response.text  # Isolate text response 
            alias_resp_json = loads(alias_resp_text)  # Convert into json format
            alias = alias_resp_json["alias"]  # Now that we have key:value pairs it's easy to extract what we want
            secret = alias_resp_json["secret"]
            print("Got temporary user alias + secret from XNAT. Combining them into encrypted token file. This will last two days and regenerate automatically unless you change your password. At that point you will be prompted to enter your password and create a new token file.")
            
            encrypt.make_token(encrypted_file_path=encrypted_alias_path, username=alias, password=secret)
            print("\nStored encrypted alias token at " + encrypted_alias_path)
            print("File needs to be decrypted before logging in, and will expire in 2 days.")
        except:
            print("XNAT denied request for alias. There could be a problem with your xnat token, so let's go ahead and renew that.")
            make_user_tkn.make_user_token()
            make_alias()    # Re-attempt alias request
        