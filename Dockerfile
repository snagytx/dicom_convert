FROM alpine

RUN apk add --no-cache lsyncd

RUN     mkdir -p /opt && \
        cd /opt && \
        wget ftp://dicom.offis.de/pub/dicom/offis/software/dcmtk/dcmtk363/bin/dcmtk-3.6.3-linux-x86_64-static.tar.bz2 && \
        tar -xvf dcmtk-3.6.3-linux-x86_64-static.tar.bz2 && \
        cd dcmtk-3.6.3-linux-x86_64-static/bin && \
        chmod +x * && \
        cp -rp /opt/dcmtk-3.6.3-linux-x86_64-static/* /usr/local && \
        rm -rf /opt && \
        mkdir /dicom_images && \
        mkdir /jpeg_images

VOLUME /etc/lsyncd

CMD ["lsyncd", "/etc/lsyncd/process.lua"]