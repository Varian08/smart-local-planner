# Smart Local Planner — Mobile Application (Flutter)

> **Mô-đun:** Ứng dụng di động đa nền tảng (Android / iOS)  
> **Kiến trúc:** Feature-First Clean Architecture kết hợp State Management `flutter_bloc`  
> **Người phụ trách:** Mobile Software Engineer (Thành viên B)  
> **Tài liệu đối chiếu:** [docs/ARCHITECTURE_BLUEPRINT.md](../docs/ARCHITECTURE_BLUEPRINT.md) | [docs/API_SPECIFICATION.md](../docs/API_SPECIFICATION.md)

---

## 🏗️ 1. Cấu trúc Thư mục Chuẩn (Feature-First Clean Architecture)

Dự án tuân thủ nghiêm ngặt nguyên tắc phân tách trách nhiệm 3 tầng độc lập:

```text
mobile/
├── assets/                         # Hình ảnh, icons, fonts vector
├── lib/
│   ├── app/                        # Cấu hình gốc ứng dụng
│   │   ├── app_router.dart         # Điều hướng màn hình (go_router)
│   │   ├── app_theme.dart          # Bộ màu và typography Material 3
│   │   └── main.dart               # Điểm khởi chạy (Entry Point)
│   ├── core/                       # Thành phần dùng chung toàn ứng dụng
│   │   ├── constants/              # ApiEndpoints, AppColors, StorageKeys
│   │   ├── network/                # Dio Client, AuthInterceptor (Token Rotation), ErrorMapper
│   │   ├── storage/                # SecureStorageService (Lưu token vào Android Keystore / iOS Keychain)
│   │   └── widgets/                # UI tái sử dụng: AppButton, AppLoading, ErrorRetry, CachedImage
│   └── features/                   # Từng phân hệ tính năng độc lập
│       ├── auth/                   # Đăng ký, Đăng nhập, Quản lý phiên làm việc
│       │   ├── data/               # AuthRepository, AuthRemoteDataSource, AuthModels
│       │   ├── bloc/               # AuthBloc, AuthEvent, AuthState
│       │   └── presentation/       # LoginScreen, RegisterScreen, widgets/
│       ├── places/                 # Khám phá địa điểm (Sprint 1)
│       │   ├── data/               # PlaceRepository, PlaceModel, PaginationResponse
│       │   ├── bloc/               # PlaceBloc, PlaceEvent, PlaceState
│       │   └── presentation/       # PlaceListScreen, PlaceDetailScreen, widgets/
│       ├── favorites/              # Địa điểm yêu thích cá nhân (Sprint 2)
│       └── itineraries/            # Lập và quản lý lịch trình du lịch (Sprint 3)
└── README.md
```

---

## ⚖️ 2. Quy chuẩn Bắt buộc (Mobile Engineering Invariants)

1. **Hợp đồng 4 trạng thái giao diện (Mandatory 4-State UI):**
   Mọi màn hình tải dữ liệu đều phải xử lý đủ 4 trạng thái:
   * `LoadingState`: Hiển thị Skeleton loading hoặc Shimmer (tránh block tương tác).
   * `SuccessState`: Hiển thị danh sách hoặc chi tiết dữ liệu.
   * `ErrorState`: Hiển thị thông điệp lỗi thân thiện kèm nút **"Thử lại" (Retry Action)**.
   * `EmptyState`: Hiển thị hình minh họa và thông báo gợi ý khi danh sách trống (`length == 0`).
2. **Quy tắc không gọi API trực tiếp từ Widget:**
   - Widget (`presentation/`) chỉ phát sự kiện (`add(Event)`).
   - `Bloc` lắng nghe sự kiện, gọi hàm trong `Repository`.
   - `Repository` sử dụng `DioClient` để giao tiếp với Backend.
   - Tuyệt đối không gọi `Dio.get()` hoặc `http.get()` trực tiếp bên trong `StatefulWidget` hay `StatelessWidget`.
3. **Bảo mật Token bằng phần cứng (Hardware Keystore):**
   - Access Token và Refresh Token **bắt buộc** lưu bằng `flutter_secure_storage`.
   - Tuyệt đối không lưu token vào `SharedPreferences` (vì SharedPreferences lưu dưới dạng file XML thuần không mã hóa).

---

## 🌐 3. Hướng dẫn Kết nối Backend Localhost

Khi chạy Backend Spring Boot ở máy phát triển (`http://localhost:8080`), thiết bị di động cần cấu hình địa chỉ IP như sau:

| Môi trường chạy Mobile | URL kết nối Backend API | Ghi chú |
| :--- | :--- | :--- |
| **Android Emulator (Máy ảo)** | `http://10.0.2.2:8080/api/v1` | IP `10.0.2.2` là alias trỏ ngược về localhost máy tính host |
| **iOS Simulator** | `http://localhost:8080/api/v1` | iOS Simulator chia sẻ trực tiếp network với máy Mac |
| **Thiết bị thật (Real Device qua Wi-Fi)** | `http://<IP_LAN_MAY_TINH>:8080/api/v1` | Cả điện thoại và máy tính cùng kết nối chung một mạng Wi-Fi (ví dụ: `http://192.168.1.15:8080/api/v1`) |

---

## 🚀 4. Lộ trình phát triển của Kỹ sư Mobile

* **Sprint 0:** Thiết lập bộ khung ứng dụng, cấu hình Dio Network Client kèm `AuthInterceptor`, tạo Theme Material 3 và cấu trúc Clean Architecture.
* **Sprint 1 (The First Vertical Slice):** Xây dựng màn hình Khám phá địa điểm (`PlaceListScreen`), tích hợp phân trang vô hạn (Infinite Scroll), hiển thị ảnh nén qua Cloudinary và xử lý đầy đủ 4 trạng thái UI.
* **Sprint 2:** Tích hợp màn hình Đăng ký / Đăng nhập, cơ chế lưu trữ token an toàn và tính năng Bookmark / Yêu thích địa điểm.
