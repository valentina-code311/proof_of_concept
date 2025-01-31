# Use an official Python base image
FROM python:3.12

# Set the working directory
WORKDIR /app

# Copy the requirements file and the application code
COPY requirements.txt .
COPY . /app

# Install dependencies
RUN pip install -r requirements.txt

# Expose the port the app runs on
EXPOSE 80

# Command to run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
