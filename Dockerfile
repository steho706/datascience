FROM python:3.7 as base

RUN wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb

RUN apt-get update; \
    apt-get install -y apt-transport-https && \
    apt-get update && \
    apt-get install -y dotnet-sdk-3.1

FROM base

#RUN pip install notebook
RUN pip install jupyterlab

RUN jupyter notebook --generate-config && \
    sed -i "s/#c.NotebookApp.notebook_dir = ''/c.NotebookApp.notebook_dir = '\/home\/notebook'/g" /root/.jupyter/jupyter_notebook_config.py && \
    mkdir /home/notebook

RUN dotnet tool install -g --add-source "https://dotnet.myget.org/F/dotnet-try/api/v3/index.json" Microsoft.dotnet-interactive
ENV PATH="$PATH:/root/.dotnet/tools"
RUN dotnet interactive jupyter install

EXPOSE 8888

RUN echo "#!/bin/sh" > entrypoint.sh && \
    echo "jupyter lab --ip=0.0.0.0 --port=8888 --allow-root" >> entrypoint.sh && \
    echo "CMD tail -f /dev/null" >> entrypoint.sh && \
    chmod +x entrypoint.sh

CMD ["./entrypoint.sh"]
