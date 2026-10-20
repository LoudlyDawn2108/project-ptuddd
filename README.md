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

## 3. Quy Trình Nộp Bài Bằng Git

Sinh viên thực hiện việc nộp bài theo các bước kỹ thuật sau:

### Bước 1: Sao chép repository về máy cục bộ (Clone)

```bash
git clone <URL_REPOSITORY>
cd project-ptuddd
```

### Bước 2: Tạo nhánh làm việc mới (Branch)

Mỗi nhóm nên tạo nhánh riêng để tránh xung đột mã nguồn:

```bash
git checkout -b feature/<ten-nhom>-<ten-lop>
```

### Bước 3: Tạo thư mục và cập nhật mã nguồn

1. Tạo thư mục nhóm: `mkdir <ten-nhom>-<ten-lop>`
2. Di chuyển vào thư mục vừa tạo và bổ sung tệp `danhsachnhom.md`.
3. Sao chép toàn bộ mã nguồn dự án vào thư mục này.

### Bước 4: Lưu trữ và gửi thay đổi lên kho lưu trữ (Commit & Push)

```bash
git add <ten-nhom>-<ten-lop>/
git commit -m "feat(<ten-nhom>): nop ma nguon va danh sach thanh vien"
git push origin feature/<ten-nhom>-<ten-lop>
```

### Bước 5: Mở Pull Request (PR)

1. Truy cập vào giao diện GitHub của repository.
2. Tạo **Pull Request** từ nhánh `feature/<ten-nhom>-<ten-lop>` vào nhánh chính `main`.
3. Tiêu đề Pull Request: `[Nộp bài] <Tên Nhóm> - <Tên Lớp>`.
4. Chờ giảng viên kiểm tra và hợp nhất (merge) mã nguồn.

---

## 4. Các Lưu Ý Kỹ Thuật Quan Trọng

1. **Phạm vi tác động:** Tuyệt đối không chỉnh sửa, di chuyển hoặc xóa tệp tin, thư mục của các nhóm khác hoặc các tệp cấu hình dùng chung ở thư mục gốc.
2. **Loại trừ tệp rác (.gitignore):** Không đẩy lên repository các thư mục phụ thuộc và tệp tạm thời như:
   - Thư mục thư viện: `node_modules/`, `Pods/`, `.gradle/`, `vendor/`
   - Thư mục biên dịch: `build/`, `dist/`, `.dart_tool/`, `bin/`, `obj/`
   - Tệp môi trường chứa khóa bảo mật: `.env`, `.env.local`, `keystore`, `*.jks`
   - Tệp cấu hình IDE cục bộ: `.idea/`, `.vscode/`, `*.suo`, `*.user`
3. **Dung lượng tệp:** Không đẩy các tệp tin có dung lượng vượt quá giới hạn của GitHub (khuyến nghị dưới 50MB/tệp).
