FROM python:3.12-slim
WORKDIR /tests
RUN pip install --no-cache-dir robotframework robotframework-requests robotframework-jsonlibrary
# tests bind-mounted at runtime
ENV BASE_URL=http://app:8080
CMD ["bash", "-lc", "robot --variable BASE_URL:$BASE_URL -d /reports /tests"]
