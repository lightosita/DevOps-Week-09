FROM python:3.12-slim-trixie
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
RUN useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin appuser
ARG APP_VERSION=1.0
ENV APP_VERSION=$APP_VERSION PYTHONUNBUFFERED=1
EXPOSE 3000
USER appuser
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:3000/health')" || exit 1
CMD ["gunicorn", "-b", "0.0.0.0:3000", "app:app"]
