## 📌 Pull Request Overview

### 1. Mô tả thay đổi (Summary of Changes)
<!-- Tóm tắt ngắn gọn mục tiêu kỹ thuật hoặc tính năng được triển khai trong PR này -->
- 

### 2. Loại thay đổi (Type of Change)
- [ ] `feat`: Tính năng mới (Feature)
- [ ] `fix`: Vá lỗi (Bug fix)
- [ ] `refactor`: Tái cấu trúc mã nguồn (không đổi logic bên ngoài)
- [ ] `test`: Bổ sung hoặc cập nhật kiểm thử (Unit / Integration tests)
- [ ] `docs`: Cập nhật tài liệu, kiến trúc hoặc hợp đồng API
- [ ] `chore`: Cấu hình build, phụ thuộc hoặc công cụ CI/CD

### 3. Phân hệ tác động (Affected Module)
- [ ] Backend (Spring Boot 3)
- [ ] Mobile (Flutter)
- [ ] Database (Flyway Migration)
- [ ] Documentation / Tooling

---

## 🛡️ Checklist Chất lượng (Definition of Done - DoD)

Vui lòng tích chọn toàn bộ các mục trước khi yêu cầu Reviewer phê duyệt:

- [ ] **Mã nguồn sạch:** Đã format code chuẩn, không để lại `TODO`, biến thừa hoặc file tạm.
- [ ] **Bảo mật:** Tuyệt đối không commit file `.env`, mật khẩu, secret keys hoặc thông tin đăng nhập.
- [ ] **Kiểm thử:** Mã nguồn đã được build và chạy thử nghiệm thành công ở môi trường local.
- [ ] **Kiến trúc:** Tuân thủ phân tầng 3 lớp (Backend: DTO Isolation; Mobile: Bloc State Management).
- [ ] **Tương thích:** Không làm phá vỡ các hợp đồng API đã thống nhất trong `docs/API_SPECIFICATION.md`.

---

## 📸 Bằng chứng Kiểm thử (Evidence / Screenshots)
<!-- Đính kèm ảnh chụp màn hình Swagger, Bruno 200 OK hoặc ảnh chụp màn hình máy ảo Mobile -->
