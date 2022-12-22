FROM python:3.8-slim

RUN apt-get update && apt-get install -y curl
RUN pip install flask
RUN mkdir -p /app
COPY receiver.py /app/
WORKDIR /app
ENV FLASK_APP=receiver.py

ENTRYPOINT ["flask", "run", "--host", "0.0.0.0", "--port", "8888"]
