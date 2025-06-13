# this is just code that helped me understand some of these

from fastapi import FastAPI
from pydantic import BaseModel
from datetime import date

app = FastAPI()

# some pydantic
class Product(BaseModel):
  name: str
  price: int
  date_added: date

# defining an endpoint: GET, POST, PUT, DELETE
# GET: get information
# POST: make something new/update server
# PUT: changing something
# DELETE: deleting stuff

# products = [{"name": "Macbook", "price": 2000, "date_added": "2025-01-21"}]
products = [Product(name="Macbook", price=2000, date_added=date(2025, 1, 11))]

@app.get('/api') # this is an endpoint
def index():
  return {"message": "Hello World"}

@app.get('/products')
def get_products() -> list[Product]: # this function specifies the return type
  return products

@app.post('/products')
def add_product(product: Product):
  products.append(product)
  return product