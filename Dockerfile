# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Set working directory inside container
WORKDIR /app

# Copy all project files into /app
COPY . /app

# Install OS-level dependencies for tkinter and other GUI libs
RUN apt-get update && apt-get install -y \
    python3-tk \
    tk-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --upgrade pip && pip install flask pytest

# Expose Flask port
EXPOSE 5000

# Run the Flask app
CMD ["python3", "ACEest_Fitness_docker.py"]
