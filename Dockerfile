FROM ubuntu:latest

RUN apt-get update && apt-get install -y nginx

RUN echo "Mission successful!" > /var/www/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]