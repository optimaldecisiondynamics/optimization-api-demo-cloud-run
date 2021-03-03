FROM openanalytics/r-base

# Install python and necessary python packages
RUN apt-get update -y \
  && apt-get upgrade -y \
  && apt-get install -y git \
  && apt-get install -y --no-install-recommends python3-pip python3-dev \
  git-core \
  libssl-dev \
  libcurl4-gnutls-dev \
  libsodium-dev

ADD requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Install CBC solver
RUN git clone https://github.com/coin-or/coinbrew /var/cbc
WORKDIR /var/cbc
RUN ./coinbrew fetch Cbc@2.10.5 --no-prompt --no-third-party
RUN ./coinbrew build Cbc --no-prompt --no-third-party --enable-cbc-parallel --prefix=/usr
ENV COIN_INSTALL_DIR /usr

ENV PATH="/var/cbc/build/Cbc/2.10.5/src:${PATH}"

WORKDIR /

COPY dog_path_analysis.R api.R plumber.R dog_max_path.py ./

# Install R packages
RUN R -e "install.packages('purrr',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('dplyr',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('zip',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('plumber',dependencies=TRUE, repos='http://cran.rstudio.com/')"

EXPOSE 8080
ENTRYPOINT ["Rscript", "api.R"]
