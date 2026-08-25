# Spring Boot and Netty Socket server for real-time game

This is an internship project in GihOt Studio.

## Setup local

1. Cài Java 17 và Maven.
2. Cài MongoDB local hoặc dùng MongoDB Atlas.
3. Cài Redis local vì project này đang dùng Redis cho matchmaking và state room.
4. Copy `src/main/resources/env.properties.example` thành `src/main/resources/env.properties`.
5. Nếu chạy local, giữ `MONGODB_URL=mongodb://localhost:27017/warcup` và `REDIS_HOST=localhost`.
6. Nếu dùng Atlas, thay `MONGODB_URL` bằng connection string `mongodb+srv://...` và add IP của máy bạn vào Atlas Network Access.
7. Start Redis, rồi build và chạy app bằng Maven wrapper hoặc jar.

### Command

```powershell
.\mvnw.cmd clean test
.\mvnw.cmd spring-boot:run
```

### One-command local start (Windows + WSL Redis)

If you run MongoDB on Windows and Redis on Debian WSL, use:

```powershell
.\start-local.ps1
```

Script behavior:

1. Ensure `src/main/resources/env.properties` exists (copy from example if missing).
2. Start MongoDB if `localhost:27017` is not listening.
3. Start Redis in WSL (`sudo service redis-server start`) if `localhost:6379` is not listening.
4. Start Spring Boot (`spring-boot:run`).

Optional params:

```powershell
.\start-local.ps1 -DistroName Debian -MongoBinPath "E:\MongoDB\mongodb-win32-x86_64-windows-7.0.40\bin\mongod.exe" -MongoDbPath "E:\MongoDB\data\db"
```

Nếu đã có jar trong `target`, chạy:

```powershell
.\startserver.bat
```

## API và socket

- REST API base prefix: `/api/v1`
- Auth: `/api/v1/auth`
- Rooms: `/api/v1/rooms`
- User: `/api/v1/user`
- Matchmaking: `/api/matchmaking/queue`
- Netty socket port mặc định: `8386`

## MongoDB Atlas

1. Tạo cluster trên Atlas.
2. Tạo database user với quyền đọc/ghi.
3. Thêm IP của máy bạn vào Network Access.
4. Lấy URI dạng `mongodb+srv://<user>:<pass>@<cluster>/warcup?retryWrites=true&w=majority&appName=WarCup`.
5. Dán URI đó vào `MONGODB_URL` trong `env.properties`.

## Local MongoDB

Nếu bạn muốn xài MongoDB local thay vì Atlas, bật MongoDB ở máy bạn và để:

```properties
MONGODB_URL=mongodb://localhost:27017/warcup
REDIS_HOST=localhost
REDIS_PORT=6379
```

## Lưu ý

- `src/main/resources/env.properties` đang bị gitignore để tránh commit secret.
- Nếu chỉ muốn đổi port HTTP hoặc Netty, sửa trong `env.properties`.
- Netty ở repo này là TCP/TLV, không phải WebSocket thuần.
