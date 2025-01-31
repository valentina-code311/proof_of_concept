from fastapi import FastAPI
import socket
import time
import psutil
import multiprocessing


app = FastAPI()


@app.get("/get-ip")
def get_ip():
    hostname = socket.gethostname()
    ip_address = socket.gethostbyname(hostname)

    return {
        "ip": ip_address,
        "hostname": hostname
    }


@app.get("/health")
def health():
    return {
        "status": "ok"
    }


def valid_usage(metrics=False, memory=50, cpu=30):
    process = psutil.Process()
    cpu_percent = process.cpu_percent(interval=1) # Porcentaje de CPU utilizado en el último segundo
    memory_percent = process.memory_info().rss / (1024 * 1024) # Porcentaje de memoria residente utilizada
    print("CPU: ", cpu_percent)
    print("MEM: ", memory_percent)

    if metrics:
        return {
            "cpu_usage": cpu_percent,
            "memory_usage": memory_percent
        }

    return cpu_percent < cpu and memory_percent < memory


@app.get("/simulate")
def simulate(memory: int = 50):

    fake_list = []

    while valid_usage(memory=memory):
        try:
            fake_list.extend([x**2 for x in range(1000)])
        except Exception as e:
            print(e)
            break

    return valid_usage(metrics=True)
