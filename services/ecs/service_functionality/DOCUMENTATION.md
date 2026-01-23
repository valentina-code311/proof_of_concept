# Proof of Concept: Service on AWS ECS

## 1. Create Base Files for API Service

* Create a file named `main.py`, with a FastAPI application with a single endpoint `/get-ip` that returns the IP address of the machine where the service is running. [see function](./app/main.py#L1-L13).

```python
from fastapi import FastAPI, Request
import socket

app = FastAPI()

@app.get("/get-ip")
async def get_ip(request: Request):
    hostname = socket.gethostname()
    ip_address = socket.gethostbyname(hostname)

    return {
        "ip": ip_address
    }
```

* Create a file named `Dockerfile` that sets up a Python environment, installs dependencies, and runs the FastAPI application using `uvicorn`. [see Dockerfile](./app/Dockerfile#L1-L18).

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
COPY . /app
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 80
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
```

* Create a `requirements.txt` file that lists the dependencies required for the FastAPI application. [see requirements](./app/requirements.txt#L1-L2).

```
fastapi==0.115.6
uvicorn==0.34.0
```

* Create a `docker-compose.yml` file with the following content. [See docker-compose](./docker-compose.yml).

```yaml
services:
  poc-app:
    container_name: poc-app
    build: app/
    command: uvicorn main:app --host 0.0.0.0 --port 80 --reload
    ports:
      - "80:80"
    volumes:
      - ./app:/app
```

> Run  `docker-compose up -d` to start the API service. Open your browser and navigate to `http://localhost:80/docs` to access the FastAPI documentation and test the `/get-ip` endpoint.

