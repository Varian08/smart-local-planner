# 🚀 CI/CD EVOLUTION ROADMAP (Lộ Trình Tiến Hóa CI)

> **Dự án:** Smart Local Planner  
> **Áp dụng cho:** `.github/workflows/ci.yml`  
> **Nguyên tắc:** *CI/CD phải tiến hóa song hành với độ chín của dự án.* Không bật các rào cản kiểm thử quá sớm khi chưa viết code, nhưng phải nâng dần độ khắt khe qua từng Sprint để đảm bảo chất lượng phần mềm chuẩn Enterprise (tương tự quy chuẩn của `eform`).

---

## 🗺️ Bản Đồ Nâng Cấp CI Theo Từng Sprint

```text
[ Sprint 0: Foundation ] ──► [ Sprint 1: Core Logic ] ──► [ Sprint 2: Fullstack ] ──► [ Sprint 3+: Release ]
  - Java 21 LTS Setup          - Backend Unit Tests          - Flutter Analyzer         - Docker Build Verification
  - Maven Dependency Cache     - Spotless / Checkstyle       - Flutter Widget Tests     - Sonatype Dependency Check
  - mvn test-compile           - Fail on Test Failure        - Flyway Migration Check   - Multi-platform Quality Gate
```

---

## 📌 GIAI ĐOẠN 1: SPRINT 0 (Hiện Tại - Nền Móng Cơ Bản)

### 🎯 Mục tiêu
Đảm bảo mã nguồn biên dịch thành công, không bị lỗi cú pháp Java, tải cache thư viện Maven mượt mà, không chặn dev khi chưa viết bài test nào.

### ⚙️ Cấu hình `ci.yml` hiện hành
* **Triggers:** `push` và `pull_request` trên `develop` và `main`.
* **Runner:** `ubuntu-latest`.
* **Actions:** `actions/checkout@v4`, `actions/setup-java@v4` (Java 21 LTS, Eclipse Temurin).
* **Lệnh chạy:**
  ```bash
  mvn -B clean test-compile
  ```
* **Lý do:** Chỉ kiểm tra biên dịch mã nguồn và cấu hình POM. Không bắt buộc phải có test case.

---

## 📌 GIAI ĐOẠN 2: SPRINT 1 (Core Backend & Data Layer)

### 🎯 Mục tiêu khi chuyển sang Sprint 1
Khi nhóm bắt đầu viết JPA Entities (`Place`), Repositories, Services và viết Unit Test đầu tiên: **Bắt buộc code phải pass test 100% mới được merge vào `develop`.**

### 🛠️ Thay đổi cần làm trong `.github/workflows/ci.yml`:
Chuyển lệnh build từ `test-compile` sang chạy kiểm thử thực thụ:

```yaml
      - name: Run Backend Unit Tests with Maven
        working-directory: backend
        run: mvn -B test
```

### 🛡️ Tiêu chuẩn chất lượng (Quality Gate):
* Mọi pull request nếu làm hỏng Unit Test cũ ➡️ **CI Báo Đỏ ❌ ➡️ Không cho phép Merge**.

---

## 📌 GIAI ĐOẠN 3: SPRINT 2 (Fullstack Integration - Thêm Mobile Flutter)

### 🎯 Mục tiêu
Khi dự án bắt đầu code Mobile (`flutter_bloc`, màn hình Flutter): Bổ sung thêm một Job chạy song song để kiểm tra Flutter (tương tự như Job `frontend` của `eform`).

### 🛠️ Cấu hình bổ sung vào `.github/workflows/ci.yml`:

```yaml
  mobile-ci:
    name: Mobile Quality Gate (Flutter)
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Java (Android dependency)
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Flutter SDK
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      - name: Install Mobile Dependencies
        working-directory: mobile
        run: flutter pub get

      - name: Static Code Analysis (Flutter Linter)
        working-directory: mobile
        run: flutter analyze

      - name: Run Mobile Unit & Widget Tests
        working-directory: mobile
        run: flutter test
```

---

## 📌 GIAI ĐOẠN 4: SPRINT 3 & PRODUCTION (Enterprise Security & Docker)

### 🎯 Mục tiêu (Đạt trọn vẹn chuẩn như `eform`)
Bổ sung các công cụ quét bảo mật tĩnh và kiểm tra đóng gói Docker trước khi đưa sản phẩm ra môi trường Production.

### 🛠️ Các Job mở rộng:

1. **Yamllint (Giống `eform`):**
   ```yaml
   yamllint:
     runs-on: ubuntu-latest
     steps:
       - uses: actions/checkout@v4
       - uses: reviewdog/action-yamllint@v1
         with:
           fail_on_error: true
   ```

2. **Hadolint (Kiểm tra Dockerfile - Giống `eform`):**
   ```yaml
   hadolint:
     runs-on: ubuntu-latest
     steps:
       - uses: actions/checkout@v4
       - uses: reviewdog/action-hadolint@v1
         with:
           fail_on_error: true
   ```

3. **Dependency Vulnerability Scan (Tương đương Nancy trong `eform`):**
   * Sử dụng **OWASP Dependency-Check** hoặc **GitHub Dependabot** để quét thư viện Spring Boot và Flutter.

---

## 📋 Checklist Chuyển Đổi Khi Sang Sprint Mới

Khi bắt đầu một Sprint mới, Tech Lead thực hiện các bước sau:
- [ ] **Bước 1:** Mở file này (`.github/CI_ROADMAP.md`).
- [ ] **Bước 2:** Đọc yêu cầu của Sprint tương ứng.
- [ ] **Bước 3:** Tạo nhánh `feature/ci-sprint-<X>`.
- [ ] **Bước 4:** Cập nhật các bước mới vào `.github/workflows/ci.yml`.
- [ ] **Bước 5:** Test thử nghiệm trên nhánh cá nhân, đảm bảo xanh mượt trước khi mở PR vào `develop`.
