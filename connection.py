from fastapi import FastAPI, WebSocket
from pydantic import BaseModel, validator
from qformatpy import qformat

import PIL.Image
from io import BytesIO
import base64

def generate_frame():
  frame = imgen_vdma.readframe()
  image = PIL.Image.fromarray(frame)
  im_file = BytesIO()
  image.save(im_file, format='PNG')


  im_b64_string = base64.b64encode(im_file.getvalue()).decode('utf-8')
  return (f"data:image/jpeg;base64,{im_b64_string}")

print(data_url)

app = FastAPI()

class Update(BaseModel):
  re_c: float
  im_c: float  
  zoom: int
  max_iter: int
  colour_sch: str
    
  @validator('re_c', 'im_c')
  def convert_to_q4_28(cls, v):
    return qformat(v, 4, 28) 
    
updates = [Update(re_c=2.1234232, im_c=-1.324567, zoom=5, max_iter=200, colour_sch="classic")]

@app.get('/updates')
def get_updates() -> list[Update]: # this function specifies the return type
  return updates

@app.post('/updates')
def add_updates(update: Update):
  updates.append(update)
  return update

@app.websocket('/websocket')
async def websocket_endpoint(websocket: WebSocket):
  await websocket.accept()
  while True:
    try:
      base_rep = generate_frame()
      await websocket.send_bytes(base_rep) # could be send_text though? - https://fastapi.tiangolo.com/reference/websockets/#fastapi.WebSocket.iter_json
      # add time buffer if necessary

    except:
      print("No valid connection made")
         
      