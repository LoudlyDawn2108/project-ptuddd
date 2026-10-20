# Hướng Dẫn Nộp Bài Tập Nhóm - Phát Triển Ứng Dụng Di Động

Tài liệu này quy định quy trình và tiêu chuẩn kỹ thuật về việc nộp bài tập lớn/dự án của các nhóm sinh viên trên kho lưu trữ (repository) này.

---

## 1. Cấu Trúc Thư Mục Nộp Bài

Mỗi nhóm sinh viên bắt buộc phải tạo một thư mục riêng biệt tại thư mục gốc của repository với quy tắc đặt tên như sau:

- **Định dạng:** `<ten-nhom>-<ten-lop>`
- **Quy cách:** Viết chữ thường, không dấu, các từ nối nhau bằng dấu gạch ngang (`-`).
- **Ví dụ hợp lệ:**
  - `nhom01-dhti15a1hn`
  - `nhom02-dhti15a2hn`

### Sơ đồ cấu trúc cây thư mục mẫu

```text
project-ptuddd/
├── README.md
├── .gitignore
├── nhom01-dhti15a1hn/
│   ├── danhsachnhom.md
│   └── src/ (hoặc toàn bộ mã nguồn của nhóm)
└── nhom02-dhti15a2hn/
    ├── danhsachnhom.md
    └── src/
```

---

## 2. Yêu Cầu Tệp danhsachnhom.md

Bên trong thư mục của mỗi nhóm, bắt buộc phải có tệp `danhsachnhom.md` khai báo thông tin các thành viên tham gia dự án theo cấu trúc bảng dưới đây:

```markdown
# Danh Sách Thành Viên - Nhóm [Tên Nhóm]

- **Lớp học phần / Lớp sinh hoạt:** [Tên Lớp]
- **Tên đề tài / ứng dụng:** [Tên dự án]
- **Giảng viên hướng dẫn:** [Tên Giảng viên]

## Bảng Thông Tin Thành Viên

| STT | Họ và Tên | Mã Sinh Viên | Vai Trò | Nhiệm Vụ Đảm Nhiệm | Đánh Giá Đóng Góp (%) |
| --- | --------- | ------------ | ------- | ------------------ | --------------------- |
| 1   | Nguyễn Văn A | 20210001 | Trưởng nhóm | Thiết kế kiến trúc, backend | 100% |
| 2   | Trần Thị B   | 20210002 | Thành viên  | Giao diện người dùng (UI/UX)| 100% |
| 3   | Lê Văn C     | 20210003 | Thành viên  | Tích hợp API và kiểm thử    | 100% |
```

---

## 3. Hướng Dẫn Tham Gia Và Thiết Lập Môi Trường Làm Việc

Sinh viên có thể tham gia và đóng góp mã nguồn theo một trong hai mô hình dưới đây tùy thuộc vào cấu hình phân quyền của giảng viên:

### Mô hình 1: Quy trình Fork & Pull Request (Khuyến nghị)

Mô hình này giúp sinh viên quản lý kho mã nguồn độc lập, tránh xung đột trực tiếp với các nhóm khác.

1. **Fork repository:** Truy cập giao diện GitHub [project-ptuddd](https://github.com/oanhcuongdo/project-ptuddd) và chọn nút **Fork** để sao chép kho lưu trữ về tài khoản cá nhân hoặc tổ chức của nhóm.
2. **Clone kho lưu trữ đã fork về máy cục bộ:**
   ```bash
   git clone https://github.com/<tai-khoan-github-cua-ban>/project-ptuddd.git
   cd project-ptuddd
   ```
3. **Thiết lập remote upstream trỏ về kho gốc của giảng viên:**
   ```bash
   git remote add upstream https://github.com/oanhcuongdo/project-ptuddd.git
   ```
4. **Kiểm tra danh sách remote:**
   ```bash
   git remote -v
   ```
   Kết quả chuẩn gồm:
   - `origin`: Trỏ về repository cá nhân/nhóm của sinh viên.
   - `upstream`: Trỏ về repository gốc của giảng viên.

---

### Mô hình 2: Quy trình Cộng Tác Trực Tiếp (Collaborator)

Áp dụng khi giảng viên thêm tài khoản sinh viên vào danh sách cộng tác viên chính thức của repository:

1. Chấp nhận thư mời tham gia (invitation) qua email hoặc thông báo trên GitHub.
2. Clone trực tiếp kho lưu trữ về máy cục bộ:
   ```bash
   git clone https://github.com/oanhcuongdo/project-ptuddd.git
   cd project-ptuddd
   ```

---

## 4. Quy Trình Commit Và Push Code Đúng Thư Mục Nhóm

Để đảm bảo tính độc lập và toàn vẹn dữ liệu giữa các nhóm, sinh viên bắt buộc phải tuân thủ nghiêm ngặt các bước thao tác sau:

### Bước 1: Cập nhật mã nguồn mới nhất từ kho gốc

Trước khi bắt đầu phiên làm việc mới, luôn đồng bộ dữ liệu mới nhất từ nhánh `main`:

```bash
# Đối với Mô hình Fork:
git checkout main
git fetch upstream
git merge upstream/main
git push origin main

# Đối với Mô hình Collaborator:
git checkout main
git pull origin main
```

### Bước 2: Tạo hoặc chuyển sang nhánh làm việc của nhóm

Mỗi nhóm làm việc trên một nhánh riêng biệt, không commit trực tiếp vào nhánh `main`:

```bash
git checkout -b feature/<ten-nhom>-<ten-lop>
```
*(Nếu nhánh đã tồn tại trên máy, sử dụng lệnh: `git checkout feature/<ten-nhom>-<ten-lop>`)*

### Bước 3: Đặt mã nguồn và tài liệu vào đúng thư mục nhóm

1. Xác định đúng thư mục của nhóm mình: `<ten-nhom>-<ten-lop>/`.
2. Kiểm tra tệp `danhsachnhom.md` đã có đầy đủ thông tin thành viên theo mẫu tại Mục 2.
3. Đặt toàn bộ mã nguồn bài tập vào bên trong thư mục này.

### Bước 4: Kiểm tra trạng thái thay đổi (Bắt buộc)

Trước khi đánh dấu tệp thay đổi (stage), chạy lệnh sau để rà soát các tệp bị ảnh hưởng:

```bash
git status
```

**Quy tắc an toàn:**
- Kiểm tra danh sách tệp trong mục *Untracked files* và *Changes not staged for commit*.
- Bắt buộc tất cả các tệp thay đổi phải nằm bên trong đường dẫn thư mục nhóm `<ten-nhom>-<ten-lop>/`.
- Nếu phát hiện tệp nằm ngoài thư mục nhóm hoặc tệp rác (build, cache, .env), phải xóa hoặc đưa vào `.gitignore` trước khi tiếp tục.

### Bước 5: Đánh dấu tệp thay đổi (Stage) theo đúng đường dẫn thư mục nhóm

**NGHIÊM CẤM:** Không sử dụng `git add .` hoặc `git add -A` tại thư mục gốc repository khi chưa kiểm tra kỹ.

Chỉ đánh dấu thư mục thuộc quyền quản lý của nhóm:

```bash
git add <ten-nhom>-<ten-lop>/
```

Trường hợp vô tình đánh dấu nhầm tệp ngoài thư mục nhóm, sử dụng lệnh hủy đánh dấu:

```bash
git restore --staged <duong-dan-tep-bi-nham>
```

### Bước 6: Lưu trữ thay đổi (Commit)

Thực hiện commit với thông điệp rõ ràng theo định dạng chuẩn:

- **Thêm mới tính năng/mã nguồn:**
  ```bash
  git commit -m "feat(<ten-nhom>): bo sung module dang nhap va xac thuc"
  ```
- **Cập nhật danh sách nhóm / tài liệu:**
  ```bash
  git commit -m "docs(<ten-nhom>): cap nhat thong tin thanh vien nhom"
  ```
- **Sửa lỗi mã nguồn:**
  ```bash
  git commit -m "fix(<ten-nhom>): sua loi hien thi danh sach san pham"
  ```

### Bước 7: Đẩy mã nguồn lên GitHub (Push)

Đẩy nhánh làm việc lên kho lưu trữ cá nhân/nhóm:

```bash
git push origin feature/<ten-nhom>-<ten-lop>
```

### Bước 8: Mở Pull Request (PR)

1. Truy cập giao diện GitHub của repository.
2. Hệ thống sẽ hiển thị gợi ý tạo Pull Request từ nhánh vừa push; chọn **Compare & pull request**.
3. Cấu hình nhánh:
   - **Base repository:** `oanhcuongdo/project-ptuddd` | **base:** `main`
   - **Head repository:** Kho của bạn | **compare:** `feature/<ten-nhom>-<ten-lop>`
4. Đặt tiêu đề: `[Nộp bài] <Tên Nhóm> - <Tên Lớp>`.
5. Phần nội dung (Description): Mô tả tóm tắt các tính năng đã thực hiện và liệt kê các thành viên nộp bài.
6. Nhấn **Create pull request**. Giảng viên sẽ tiến hành review và hợp nhất mã nguồn.

---

## 5. Phối Hợp Làm Việc Nội Bộ Trong Nhóm

Đối với các nhóm có nhiều thành viên cùng phát triển đồng thời:

1. **Phân chia nhánh nội bộ:**
   - Các thành viên có thể tạo nhánh phụ từ nhánh nhóm: `feature/<ten-nhom>/<tinh-nang>` hoặc `<ten-nhom>-<ten-thanh-vien>`.
   - Khi hoàn thành tính năng, tiến hành merge vào nhánh chính của nhóm `feature/<ten-nhom>-<ten-lop>` trước khi gửi Pull Request về kho gốc của giảng viên.
2. **Quy tắc giải quyết xung đột (Conflict Resolution):**
   - Không được ghi đè mã nguồn của thành viên khác mà không trao đổi nội bộ.
   - Luôn chạy kiểm thử ứng dụng sau khi giải quyết xung đột mã nguồn.

---

## 6. Các Lưu Ý Kỹ Thuật Quan Trọng

1. **Phạm vi tác động:** Tuyệt đối không chỉnh sửa, di chuyển hoặc xóa tệp tin, thư mục của các nhóm khác hoặc các tệp cấu hình dùng chung ở thư mục gốc (`README.md`, `.gitignore`).
2. **Loại trừ tệp rác (.gitignore):** Không đẩy lên repository các thư mục phụ thuộc và tệp tạm thời như:
   - Thư mục thư viện: `node_modules/`, `Pods/`, `.gradle/`, `vendor/`
   - Thư mục biên dịch: `build/`, `dist/`, `.dart_tool/`, `bin/`, `obj/`
   - Tệp môi trường chứa khóa bảo mật: `.env`, `.env.local`, `keystore`, `*.jks`
   - Tệp cấu hình IDE cục bộ: `.idea/`, `.vscode/`, `*.suo`, `*.user`
3. **Dung lượng tệp:** Không đẩy các tệp tin có dung lượng vượt quá giới hạn của GitHub (khuyến nghị dưới 50MB/tệp).

