# Flutter application

The blog form takes a photo, previews it, and sends it with the title,
description, and optional tags to `POST /blog` as `multipart/form-data`.
FastAPI stores the image under `backend_API/uploads` and saves its public path
in the existing `blog.img` column.

The FastAPI dependencies, including `python-multipart`, are listed in
`backend_API/requirements.txt`.

The API URL defaults to `http://127.0.0.1:8000`. Override it at build/run time
with `API_BASE_URL` when using a different host. For example, an Android
emulator typically reaches the development computer at `10.0.2.2`; a physical
device needs the computer's LAN IP. The development Android build permits
unencrypted HTTP; production should use HTTPS.
