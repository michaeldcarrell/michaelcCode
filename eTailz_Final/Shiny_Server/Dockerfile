FROM rocker/shiny:3.3.2

RUN sudo apt-get install -y \
  libmariadb-client-lgpl-dev

RUN R -e 'install.packages(c("RMySQL", "shinyjs"))'

RUN mkdir /home/shiny/lib

EXPOSE 3838

CMD ["/usr/bin/shiny-server.sh"]
