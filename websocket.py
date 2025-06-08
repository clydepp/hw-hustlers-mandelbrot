from fastapi import FastAPI
from PIL import Image
import base64
from io import BytesIO

api = FastAPI()

# defining an endpoint: GET, POST, PUT, DELETE
# GET: get information
# POST: make something new/update server
# PUT: changing something
# DELETE: deleting stuff

@api.get('/')
def index():
  return {"message": "Hello World"}

# don't make this into an async function:
# @api.get('/calculation')
# def calculation():
#     return ""

@api.post('/')
async def update_params():
  

