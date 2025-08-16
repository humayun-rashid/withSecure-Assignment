"""
AWS Lambda entrypoint via Mangum (API Gateway HTTP API v2).
Set container CMD to: ["listservice.handler.handler"]
"""
from mangum import Mangum
from .main import app

handler = Mangum(app)
