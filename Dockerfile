FROM python:3.8-slim AS backend-build

WORKDIR /backend

ADD backend .

RUN python -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

RUN pip install .

FROM node AS frontend-build

WORKDIR /frontend

ADD frontend .

RUN npm install

RUN npm run build

FROM python:3.8-slim

COPY --from=frontend-build /frontend/dist /frontend/dist

COPY backend /app/backend/
COPY --from=backend-build /opt/venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app/backend

RUN apt update

RUN apt install nginx -y

# Expose both http and https
EXPOSE 80 443

COPY nginx.conf /etc/nginx/sites-available/default

COPY entrypoint.sh .

RUN chmod +x entrypoint.sh

# Running as non root user for OpenShift
RUN useradd -ms /bin/bash unicorn

ENV USER=unicorn
ENV GROUP=unicorn

RUN mkdir -p /var/cache/nginx && chown -R ${USER}:${GROUP} /var/cache/nginx && \
    mkdir -p /var/log/nginx  && chown -R ${USER}:${GROUP} /var/log/nginx && \
    mkdir -p /var/lib/nginx  && chown -R ${USER}:${GROUP} /var/lib/nginx && \
    touch /run/nginx.pid && chown -R ${USER}:${GROUP} /run/nginx.pid && \
    mkdir -p /etc/nginx/templates /etc/nginx/ssl/certs && \
    chown -R ${USER}:${GROUP} /etc/nginx && \
    chmod -R 777 /etc/nginx/conf.d

# Used to remove warning
RUN sed -i 's/user www-data;/#user www-data;/g' /etc/nginx/nginx.conf

USER ${USER}

# Call entry point script to start both nginx and gunicorn
ENTRYPOINT [ "/app/backend/entrypoint.sh" ]