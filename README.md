# Smart Local Planner

> **Hệ thống hỗ trợ khám phá địa điểm và lập lịch trình du lịch địa phương thông minh**  
> Dự án phối hợp giữa **Backend (Spring Boot 3, Java 21)** và **Mobile (Flutter BLoC)** theo tiêu chuẩn kỹ thuật doanh nghiệp (Enterprise Standard).

---

## 📌 1. Tài liệu Kiến trúc, Tiêu chuẩn & Hợp đồng Dữ liệu

Toàn bộ quy chuẩn kiến trúc, hướng dẫn phát triển, đặc tả API và nhật ký quyết định kiến trúc (ADR) được quy định chi tiết tại:

* 📐 **[docs/ARCHITECTURE_BLUEPRINT.md](docs/ARCHITECTURE_BLUEPRINT.md)** — Hồ sơ thiết kế tổng thể kiến trúc hệ thống (Technical English).
* 📖 **[docs/DEVELOPMENT_GUIDELINES.md](docs/DEVELOPMENT_GUIDELINES.md)** — Tiêu chuẩn lập trình, phân tầng 3 lớp và checklist chất lượng.
* 📡 **[docs/API_SPECIFICATION.md](docs/API_SPECIFICATION.md)** — Đặc tả chi tiết Request/Response JSON contract cho 14 endpoints MVP.
* 🗄️ **[docs/schema.sql](docs/schema.sql)** — Cấu trúc cơ sở dữ liệu PostgreSQL 16 hoàn chỉnh (UUID, FKs, Indexes).
* 🏛️ **[docs/adr/README.md](docs/adr/README.md)** — Nhật ký quyết định kiến trúc (Architecture Decision Records 0001 - 0005).

---

## 🛠️ 2. Tech Stack Chính (100% Free & Production-Ready)

| Phân hệ | Công nghệ | Mục đích | Phụ trách |
|---|---|---|:---:|
| **Mobile App** | **Flutter (Material 3) + Dart** | Giao diện Android / iOS | Mobile Engineer (Người B) |
| **State Management** | **`flutter_bloc`** | Quản lý trạng thái phân tách UI & Logic | Mobile Engineer (Người B) |
| **Mobile Network** | **`dio` + Interceptor** | Quản lý request, tự động refresh token | Mobile Engineer (Người B) |
| **Backend API** | **Java 21 + Spring Boot 3.3.x** | RESTful API, DTO pattern | Backend Engineer (Người A) |
| **Bảo mật** | **Spring Security + JWT** | Access Token (30m) & Refresh Token (7d) | Backend Engineer (Người A) |
| **Database Migration**| **Flyway** | Quản lý phiên bản CSDL bằng script SQL | Backend Engineer (Người A) |
| **Database** | **PostgreSQL 16** | Local (Docker) & Production (Neon.tech) | Backend Engineer (Người A) |
| **Cloud Storage** | **Cloudinary** | Tối ưu lưu trữ và nén ảnh qua CDN | Cả hai |
| **API Testing** | **Bruno + Swagger UI** | Kiểm thử & tài liệu hóa API | Cả hai |

---

## 📂 3. Cấu trúc Dự án (Repository Scaffolding)

```text
smart-local-planner/
├── .github/                           # Quy chuẩn GitHub (Workflows, PR Template)
│   ├── PULL_REQUEST_TEMPLATE.md       # Mẫu checklist DoD khi mở PR
│   └── workflows/
│       └── ci.yml                     # Tự động kiểm tra build Maven khi mở PR
├── docs/                              # Toàn bộ hồ sơ kiến trúc, ADR và data contracts
├── backend/                           # Mã nguồn Spring Boot 3 (API Service)
│   ├── src/main/resources/db/migration/ # Flyway Migration scripts (V1, V2...)
│   └── pom.xml                        # Maven dependencies & build plugins
├── mobile/                            # Khung mã nguồn Flutter (Clean Architecture)
│   ├── README.md                      # Hướng dẫn chi tiết dành riêng cho kỹ sư Mobile
│   └── lib/                           # app/, core/, features/ (auth, places, itineraries)
├── bruno/                             # Bộ sưu tập kiểm thử API mã nguồn mở Bruno
│   ├── README.md                      # Hướng dẫn mở và chạy kiểm thử bằng Bruno
│   └── bruno.json
├── docker-compose.yml                 # Khởi chạy PostgreSQL 16 container cục bộ
├── .env.example                       # Biến môi trường mẫu (Zero Hardcoded Secrets)
├── .dockerignore                      # Loại trừ file rác khi build Docker
├── .gitignore                         # Chặn file nhạy cảm và cache trình biên dịch
└── README.md                          # Sổ tay hướng dẫn onboarding dự án
```

---

## ⚡ 4. Hướng dẫn Khởi chạy Nhanh (Developer Quickstart)

### Yêu cầu cài đặt trước (Prerequisites):
- **Docker Desktop** (hoặc Docker Engine).
- **Java 21** (JDK 21 LTS - Temurin / Oracle).
- **Maven 3.9+** (hoặc dùng Maven wrapper trong IDE).
- **Flutter SDK 3.x** (dành cho phát triển Mobile).
- **Bruno API Client** (tùy chọn, dùng để test API).

---

### Bước 1: Khởi chạy Cơ sở dữ liệu PostgreSQL (Docker)
Tại thư mục gốc `smart-local-planner/`, mở terminal và chạy:
```bash
docker compose up -d
```
> Kiểm tra container `smart_local_planner_db` đã ở trạng thái `healthy` tại cổng `localhost:5432`.

### Bước 2: Khởi động Backend Spring Boot
Mở thư mục `backend/` trong IntelliJ IDEA hoặc VS Code, hoặc chạy bằng lệnh:
```bash
cd backend
mvn spring-boot:run
```
*Flyway sẽ tự động kích hoạt và áp dụng các kịch bản di trú cơ sở dữ liệu (`V1__init_schema.sql`).*

### Bước 3: Kiểm tra Kết nối & Tài liệu Swagger
Sau khi server báo `Started BackendApplication in X seconds`:
* **Swagger UI (Interactive API Docs):** [http://localhost:8080/swagger-ui/index.html](http://localhost:8080/swagger-ui/index.html)
* **Actuator Healthcheck:** [http://localhost:8080/actuator/health](http://localhost:8080/actuator/health) (Trả về `{"status":"UP"}`)
* **API Testing:** Mở thư mục `bruno/` trong phần mềm Bruno để gửi request mẫu.

### Bước 4: Khởi chạy Mobile Flutter
Xem hướng dẫn chi tiết dành cho lập trình viên di động tại: **[mobile/README.md](mobile/README.md)**.

---

## 🌿 5. Quy chuẩn Nhánh Git & Phối hợp Nhóm (Branching Strategy)

Dự án áp dụng mô hình phân nhánh chuẩn doanh nghiệp (**GitFlow Phân tách Tích hợp**):

```
[main] ───────────────────────────────────────────────► Bản phát hành ổn định (Production)
   ▲
   │ (Pull Request khi hoàn thành Sprint)
[develop] ────────────────────────────────────────────► Nhánh tích hợp chính (MẶC ĐỊNH)
   ▲                     ▲
   │ (PR Backend)        │ (PR Mobile)
[feature/backend-...] [feature/flutter-...]           ► Nhánh tính năng cá nhân
```

### Quy tắc làm việc:
1. **Nhánh mặc định (Default Branch):** Là `develop`. Mọi nhánh tính năng đều tách từ `develop` và mở Pull Request gộp về `develop`.
2. **Quy ước đặt tên nhánh:**
   - Backend: `feature/backend-<tên_tính_năng>` (Ví dụ: `feature/backend-places`)
   - Mobile: `feature/flutter-<tên_tính_năng>` (Ví dụ: `feature/flutter-places`)
   - Sửa lỗi: `fix/<vấn_đề>`
3. **Quy ước Commit (Conventional Commits):**
   - `feat(places): implement search endpoint with pagination`
   - `fix(auth): handle token expiration gracefully`
   - `docs(readme): add developer quickstart guide`
4. **Không commit trực tiếp vào `main` hoặc `develop`:** Luôn tạo nhánh và mở Pull Request kèm bằng chứng kiểm thử (Screenshot / Bruno result).

---

## 👥 6. Thành viên tham gia

* **Kỹ sư Backend (Người A):** Phụ trách Kiến trúc API, Database Migration, Security & Server Deployment.
* **Kỹ sư Mobile (Người B):** Phụ trách Flutter UI/UX, BLoC State, Network Client & Xử lý Edge Cases.
