# BÁO CÁO CHI TIẾT ĐÓNG GÓP VÀ PHÂN CÔNG CÔNG VIỆC CÁC THÀNH VIÊN
## DỰ ÁN: HỆ THỐNG QUẢN LÝ TÀI LIỆU ĐA NỀN TẢNG VỚI FLUTTER, FIREBASE VÀ SUPABASE

- **Lớp học phần / Lớp sinh hoạt:** 65KTPM
- **Nhóm thực hiện:** Nhóm 11
- **Giảng viên hướng dẫn:** Thầy Đỗ Oanh Cường
- **Kho lưu trữ mã nguồn:** `https://github.com/LoudlyDawn2108/project-ptuddd` (Nhánh: `nhom/nhom11-65ktpm`)

---

## BẢNG TỔNG HỢP ĐÓNG GÓP THÀNH VIÊN

| STT | Họ và Tên | Mã Sinh Viên | Email GitHub | Vai Trò Chính | Đóng Góp (%) |
| :---: | :--- | :---: | :--- | :--- | :---: |
| **1** | **Nguyễn Hồng Phúc** | **2351170611** | `tomnguyen1510.4@gmail.com` | Trưởng nhóm, Kiến trúc hệ thống, Firebase Auth & Supabase Storage | **100%** |
| **2** | **Chu Hữu Đệ** | **2251172273** | `chuhude01022004@gmail.com` | Kỹ sư CSDL SQLite Drift, Supabase SQL Schema & 11 Chính sách RLS | **100%** |
| **3** | **Pham Ngoc Bao** | **2251172249** | `ngocbao26012004@gmail.com` | Kỹ sư Giao diện UI/UX Flutter, Cloud Sharing Screen & Dialog RLS | **100%** |
| **4** | **Lê Tuấn Khanh** | **2351170601** | `khanhx419@gmail.com` | Động cơ tìm kiếm lọc dữ liệu, QA/QC & Bộ kiểm thử tự động RLS 3 User | **100%** |
| **5** | **Đinh Thị Hoa** | **2351170593** | `dinhthihoa2k5@gmail.com` | Phân tích nghiệp vụ, Chuẩn bị dữ liệu mẫu, Slide & Biên soạn Báo cáo | **100%** |

---

## 1. NGUYỄN HỒNG PHÚC (MSSV: 2351170611) — TRƯỞNG NHÓM

### 1.1. Những việc đã làm (What)
1. **Khởi tạo và thiết lập khung dự án đa nền tảng:**
   - Khởi tạo dự án Flutter `study_material_manager` hỗ trợ đầy đủ 6 nền tảng: Android, iOS, Web, Linux Desktop, macOS, Windows.
   - Thiết lập cấu trúc thư mục phân tầng sạch theo nguyên lý **Clean Architecture** (Presentation, Domain, Database/Persistence, State Management).
   - Xây dựng hệ thống giao diện **Material 3 Theme** (`lib/core/app_theme.dart`) với bảng màu hài hòa và hỗ trợ chế độ Sáng/Tối (Light/Dark Mode).
2. **Tích hợp hệ sinh thái Firebase (Checklist 1):**
   - Đăng ký và kết nối dự án Firebase chính thức của nhóm: `study-material-nhom11` (Project Number: `693074823537`, Package ID: `vn.nhom11.studydocs.study_material_manager`).
   - Cấu hình file định danh `google-services.json` vào Android Runner và tạo tệp cấu hình đa nền tảng `lib/firebase_options.dart`.
   - Triển khai dịch vụ xác thực `AuthService` (`lib/domain/services/auth_service.dart`) hỗ trợ đăng nhập bằng tài khoản Google (Google Sign-In) và dịch vụ đồng bộ đám mây Firestore `FirebaseSyncService`.
   - Xây dựng `AuthProvider` (`lib/state/auth_provider.dart`) quản lý phiên đăng nhập thời gian thực.
3. **Tích hợp Supabase Client & Storage (Checklist 2 & 4):**
   - Cấu hình kết nối Supabase qua `SupabaseConfig` (`lib/core/supabase_config.dart`) và khởi tạo SDK trong `lib/main.dart` với tham số bảo mật `publishableKey`.
   - Triển khai dịch vụ đám mây `SupabaseDocumentService` (`lib/domain/services/supabase_document_service.dart`) đảm nhiệm việc tải tệp tin vật lý lên Supabase Storage bucket `study-documents`.
   - Xây dựng phương thức đồng bộ thông tin tài khoản người dùng từ Google Auth sang bảng `public.profiles` của Supabase qua `upsertUserProfile()`.
4. **Quản trị dự án & Đóng gói sản phẩm:**
   - Điều phối phân công công việc, quản lý lịch sử Git commit, xử lý merge và đóng gói kho lưu trữ nộp bài.

### 1.2. Cách thức thực hiện kỹ thuật (How)
- **Tách tầng độc lập (Strict Layer Separation):** Đảm bảo mã nguồn trong tầng `Domain` và `Database` không import các thư viện UI Flutter (`package:flutter/material.dart` hoặc `widgets.dart`), chỉ sử dụng `package:flutter/foundation.dart`, giúp hệ thống đạt tính độc lập cao và dễ dàng kiểm thử tự động.
- **Xác thực Google OAuth 2.0:** Sử dụng thư viện `google_sign_in` lấy `GoogleSignInAuthentication` chứa cặp `idToken` và `accessToken`, sau đó kích hoạt `FirebaseAuth.instance.signInWithCredential()`. Ngay sau khi đăng nhập thành công, hệ thống tự động gọi hàm `SupabaseProvider.syncFromAuthUser()` để đồng bộ thông tin người dùng sang Supabase.
- **Cấu trúc lưu trữ tệp tin trên Supabase Storage:** Sử dụng phương thức `uploadBinary` của Supabase Client để đưa mảng byte của file vào đường dẫn `$userId/${timestamp}_$fileName`, sau đó nhận về Public URL an toàn để gắn trực tiếp vào trường `file_url` của bảng tài liệu.

---

## 2. CHU HỮU ĐỆ (MSSV: 2251172273) — KỸ SƯ CSDL & BACKEND DOMAIN

### 2.1. Những việc đã làm (What)
1. **Thiết kế Cơ sở dữ liệu Cục bộ SQLite Drift (Checklist 3):**
   - Xây dựng 4 bảng dữ liệu cốt lõi trong Drift:
     - `DocumentsTable`: Quản lý siêu dữ liệu tài liệu học tập (mã UUID, tiêu đề, loại tài liệu, nội dung, đường dẫn tệp, môn học, mức ưu tiên, trạng thái học tập).
     - `SubjectsTable`: Quản lý danh mục học phần/môn học.
     - `DeleteLogsTable`: Quản lý vết xóa dữ liệu (Tombstones).
     - `AppSettingsTable`: Quản lý cấu hình cục bộ của người dùng.
   - Cấu hình bộ điều phối kết nối cơ sở dữ liệu đa nền tảng (`lib/database/connection/`) hỗ trợ cả `NativeDatabase` (Desktop/Mobile) và `WasmDatabase` (Web browser).
2. **Triển khai các Data Access Objects (DAOs):**
   - Viết các lớp DAO chuyên trách: `DocumentDao`, `SubjectDao`, `DeleteLogDao`, `SettingsDao` với các phương thức phản ứng dữ liệu thời gian thực (Reactive Stream Queries).
3. **Thiết kế Cơ sở dữ liệu Quan hệ trên Supabase PostgreSQL (Checklist 3):**
   - Thiết kế chuẩn hóa 3NF gồm 3 bảng quan hệ trong tệp `supabase_schema_and_rls.sql`:
     - Bảng 1: `public.profiles` (Lưu thông tin định danh người dùng Google).
     - Bảng 2: `public.documents` (Lưu thông tin chi tiết tài liệu và liên kết tệp).
     - Bảng 3: `public.document_permissions` (Lưu bảng phân quyền chia sẻ đa người dùng với 2 mức `VIEW` và `EDIT`).
4. **Thiết lập 11 Chính sách Bảo mật Row Level Security - RLS (Checklist 5):**
   - Bật RLS trên toàn bộ 3 bảng và viết các policy kiểm soát truy cập nghiêm ngặt cho `SELECT`, `INSERT`, `UPDATE`, `DELETE`.
5. **Xây dựng Tầng Dịch vụ Nghiệp vụ (Domain Services):**
   - `DocumentService`: Thực thi thêm, sửa, xóa tài liệu kèm cơ chế phân giải xung đột Last-Write-Wins.
   - `SubjectService`: Quản lý nghiệp vụ danh mục học phần.
   - `BackupRestoreService`: Sao lưu toàn bộ dữ liệu ra tệp JSON Snapshot và khôi phục dữ liệu an toàn.

### 2.2. Cách thức thực hiện kỹ thuật (How)
- **Cơ chế Soft-Delete & Tombstone:** Khi xóa một tài liệu trong `DocumentDao.deleteDocument()`, hệ thống tự động ghi nhận một bản ghi vào `DeleteLogsTable` với `dateTimeDeleted = DateTime.now()`. Khi người dùng thực hiện sao lưu hoặc khôi phục dữ liệu, `BackupRestoreService` sẽ kiểm tra danh sách Tombstones này để ngăn chặn việc dữ liệu đã bị xóa bị hồi sinh lại.
- **Chiến lược Phân giải Xung đột Last-Write-Wins (LWW):** Trong `DocumentService.updateDocument()`, trường `dateTimeModified` luôn được cập nhật lại theo thời gian thực để làm căn cứ giải quyết xung đột khi đồng bộ nhiều nguồn dữ liệu.
- **Kỹ thuật viết chính sách RLS trên PostgreSQL:**
  - Đối với `SELECT`: Cho phép người dùng đọc tài liệu nếu họ là chủ sở hữu (`owner_id = auth.uid()::text`), hoặc tài liệu được đặt ở chế độ công khai (`is_public = TRUE`), hoặc email của họ xuất hiện trong bảng `document_permissions` thông qua truy vấn lồng `EXISTS (SELECT 1 FROM document_permissions WHERE ... AND LOWER(shared_with_email) = LOWER(auth.jwt() ->> 'email'))`.
  - Đối với `UPDATE`: Kiểm tra điều kiện người dùng là `OWNER` hoặc có mức quyền `permission_level = 'EDIT'` trong bảng phân quyền.
  - Đối với `DELETE`: Giới hạn độc quyền chỉ cho phép chủ sở hữu (`owner_id = auth.uid()::text`). Mọi tài khoản khác dù có quyền `EDIT` cũng không được phép xóa tài liệu.

---

## 3. PHẠM VŨ NGỌC BẢO (MSSV: 2251172249) — KỸ SƯ GIAO DIỆN UI/UX

### 3.1. Những việc đã làm (What)
1. **Xây dựng các thành phần giao diện tái sử dụng (Reusable Widgets):**
   - `DocumentCard`: Thẻ hiển thị tài liệu học tập trực quan, hiển thị nhãn môn học, mức độ ưu tiên bằng màu sắc, huy hiệu quyền hạn đám mây (`OWNER`, `EDIT`, `VIEW`) và các nút thao tác nhanh.
   - `EmptyStateView`: Màn hình trạng thái trống thân thiện khi chưa có dữ liệu hoặc không tìm thấy kết quả tìm kiếm.
2. **Triển khai hệ thống màn hình chức năng chính:**
   - `HomeScreen`: Màn hình chính sử dụng `IndexedStack` và `NavigationBar` 5 tab (Tài liệu, Môn học, Cloud RLS, Thống kê, Cài đặt).
   - `AddEditDocumentScreen`: Màn hình thêm và chỉnh sửa thông tin tài liệu kèm kiểm tra dữ liệu đầu vào (Validation).
   - `DocumentDetailScreen`: Màn hình xem chi tiết nội dung tóm tắt, học phần và trạng thái tài liệu.
   - `SubjectsScreen`: Màn hình quản lý danh sách học phần, thêm môn học mới kèm mã màu nhận diện.
   - `StatisticsScreen`: Màn hình thống kê số lượng tài liệu theo môn học, theo mức độ ưu tiên và theo trạng thái học tập.
   - `SettingsScreen`: Quản lý giao diện, trạng thái tài khoản đăng nhập Google và chức năng sao lưu/khôi phục dữ liệu JSON.
3. **Xây dựng giao diện Đám mây & Phân quyền RLS (Checklist 4):**
   - `CloudSharingScreen`: Màn hình quản lý tài liệu đám mây trên Supabase, tích hợp thanh chuyển đổi nhanh giữa 3 tài khoản kiểm thử và bộ lọc phạm vi quyền hạn.
   - `ShareDocumentDialog`: Hộp thoại chia sẻ tài liệu cho người khác, cho phép chọn mức quyền (`VIEW` / `EDIT`), xem danh sách người đang được chia sẻ và nút thu hồi quyền tức thì.
4. **Thiết kế Slide thuyết trình:**
   - Biên soạn bộ Slide giới thiệu hệ thống và hướng dẫn cấu hình Firebase (`SLIDE_TIM_HIEU_VA_SETUP_FIREBASE.pptx` & `.html`) với chuẩn cỡ chữ 22pt dễ theo dõi khi trình chiếu.

### 3.2. Cách thức thực hiện kỹ thuật (How)
- **Giao diện thích ứng (Responsive UI) & Material 3:** Sử dụng linh hoạt các widget `LayoutBuilder`, `SingleChildScrollView`, `Card`, `FilledButton`, `Chip` kết hợp với hệ màu `Theme.of(context).colorScheme`, đảm bảo giao diện hiển thị chuẩn xác trên cả màn hình điện thoại di động lẫn trình duyệt web máy tính.
- **Khóa thao tác theo ngữ cảnh quyền hạn (Context-Aware UI):** Trong `CloudSharingScreen`, các nút thao tác **Chỉnh sửa**, **Chia sẻ**, **Xóa** được kiểm soát trạng thái động thông qua các hàm logic:
  - Nút **Sửa**: Chỉ hiển thị hoặc kích hoạt nếu `doc.canEdit(currentUserId, currentUserEmail)` trả về `true` (vai trò `OWNER` hoặc `EDIT`).
  - Nút **Xóa** và **Chia sẻ**: Chỉ kích hoạt nếu `doc.canDelete()` / `doc.canShare()` trả về `true` (chỉ duy nhất vai trò `OWNER`). Nếu là người dùng có quyền `VIEW`, các nút này sẽ tự động bị ẩn hoặc vô hiệu hóa, ngăn chặn vi phạm từ tầng UI.
- **Trình mô phỏng chuyển đổi tài khoản:** Thiết kế thanh `SegmentedButton` hoặc `Wrap` gồm 3 chip tài khoản: Alice (`Owner`), Bob (`Editor`), Charlie (`Viewer`), cho phép người dùng click chuyển đổi danh tính ngay lập tức để quan sát sự thay đổi của danh sách tài liệu và quyền hạn tương ứng.

---

## 4. LÊ TUẤN KHANH (MSSV: 2351170601) — KỸ SƯ QA/QC & TESTING

### 4.1. Những việc đã làm (What)
1. **Phát triển Động cơ Tìm kiếm & Lọc dữ liệu thuần túy (Checklist 4):**
   - Xây dựng lớp logic `SearchFilterEngine` (`lib/domain/services/search_filter_engine.dart`) hoạt động độc lập với cơ sở dữ liệu, cho phép tìm kiếm và lọc đa tiêu chí tức thì trên bộ nhớ RAM.
   - Xây dựng widget `SearchFilterBar` (`lib/ui/widgets/search_filter_bar.dart`) tích hợp ô nhập từ khóa tìm kiếm và các chip lọc trạng thái, môn học.
2. **Thiết lập Bộ kiểm thử Tự động Cấp thấp (Unit Tests):**
   - Viết bài test ranh giới kiến trúc `layer_separation_test.dart` nhằm kiểm soát việc phân tách tầng mã nguồn (Domain và Database không được import UI).
   - Viết các bài test cho tầng DAO: `document_dao_test.dart`, `subject_dao_test.dart`, `delete_log_dao_test.dart`.
   - Viết các bài test cho tầng Service: `document_service_test.dart`, `backup_restore_service_test.dart`, `search_filter_engine_test.dart`.
3. **Phát triển Bộ kiểm thử Phân quyền RLS trên 3 Tài khoản Độc lập (Checklist 6):**
   - Xây dựng tệp kiểm thử `supabase_rls_multi_user_test.dart` hiện thực 6 kịch bản kiểm thử bảo mật RLS giữa 3 tài khoản người dùng:
     - **Tài khoản 1 (Alice):** `alice@nhom11.edu.vn` (Vai trò `OWNER`).
     - **Tài khoản 2 (Bob):** `bob@nhom11.edu.vn` (Vai trò `EDITOR`).
     - **Tài khoản 3 (Charlie):** `charlie@nhom11.edu.vn` (Vai trò `VIEWER`).
4. **Kiểm tra chất lượng mã nguồn & Linter:**
   - Thực thi lệnh phân tích tĩnh `flutter analyze`, khắc phục triệt để các cảnh báo mã lỗi (bao gồm thay thế `anonKey` lỗi thời bằng `publishableKey`).
   - Đảm bảo 100% test cases vượt qua thành công với lệnh `flutter test`.

### 4.2. Cách thức thực hiện kỹ thuật (How)
- **Kỹ thuật In-Memory Database Testing:** Sử dụng `NativeDatabase.memory()` để khởi tạo cơ sở dữ liệu SQLite ảo trong RAM trước mỗi ca kiểm thử (`setUp()`) và đóng kết nối sau khi hoàn tất (`tearDown()`). Kỹ thuật này giúp các bài kiểm thử chạy với tốc độ cực nhanh (vài mili-giây), độc lập hoàn toàn và không để lại tệp rác trên ổ cứng.
- **Hiện thực 6 Kịch bản Kiểm thử RLS chi tiết (`supabase_rls_multi_user_test.dart`):**
  1. *Kiểm thử `SELECT`:* Xác minh Alice thấy 3 tài liệu (gồm cả tài liệu riêng tư `doc-002`), trong khi Bob và Charlie chỉ thấy 2 tài liệu và bị ẩn hoàn toàn `doc-002`.
  2. *Kiểm thử `OWNER`:* Xác minh Alice tải file lên Storage, tạo mới, chỉnh sửa, chia sẻ và xóa tài liệu thành công.
  3. *Kiểm thử `EDITOR`:* Xác minh Bob sửa thành công tài liệu `doc-001`, nhưng khi Bob cố xóa hoặc cố chia sẻ tiếp cho người thứ 4, hệ thống lập tức ném ra ngoại lệ `PermissionDeniedException`.
  4. *Kiểm thử `VIEWER`:* Xác minh Charlie chỉ có quyền xem trên `doc-001`, mọi thao tác sửa hoặc xóa đều bị từ chối; đồng thời xác minh Charlie sửa thành công `doc-003` vì đã được Bob cấp quyền `EDIT`.
  5. *Kiểm thử `REVOKE`:* Alice thu hồi quyền của Bob trên `doc-001`; xác minh ngay sau đó `doc-001` biến mất khỏi danh sách của Bob và Bob không thể sửa được nữa.
  6. *Kiểm thử Tìm kiếm & Lọc phạm vi:* Kiểm tra kết quả tìm kiếm theo từ khóa và lọc theo phạm vi `ALL`, `OWNED`, `SHARED` với từng tài khoản người dùng.

---

## 5. ĐINH THỊ HOA (MSSV: 2351170593) — PHÂN TÍCH NGHIỆP VỤ & TÀI LIỆU KỸ THUẬT

### 5.1. Những việc đã làm (What)
1. **Khai báo và Quản trị Hồ sơ Nhóm:**
   - Soạn thảo và chuẩn hóa tệp `danhsachnhom.md` theo quy định Mục 2 trong Hướng dẫn của Giảng viên (khai báo đầy đủ họ tên, mã sinh viên, lớp 65KTPM, phân công nhiệm vụ và tỷ lệ đóng góp 100%).
2. **Thu thập và Chuẩn bị Tập Dữ liệu Mẫu (Sample Datasets):**
   - Thu thập và chuẩn hóa dữ liệu tài liệu học tập thực tế cho sinh viên ngành Công nghệ phần mềm:
     - Bài giảng Giải tích 1 (Đạo hàm và Tích phân - Môn MATH101).
     - Đề cương Ôn tập Cấu trúc Dữ liệu & Giải thuật (Môn CS102 - Chế độ riêng tư).
     - Bài tập Lớn Lập trình Đa nền tảng Flutter & Supabase (Môn IT308 - Chia sẻ nhóm).
     - Đề cương Nhập môn Trí tuệ Nhân tạo (Môn AI201).
   - Chuẩn bị các file tài liệu PDF mẫu và đường dẫn lưu trữ tương ứng trên Supabase Storage bucket `study-documents`.
3. **Phân tích Nghiệp vụ & Lập phương án Cloud:**
   - Phân tích sự khác biệt giữa mô hình quản lý tài liệu truyền thống (Local-Only / On-Premise) và mô hình hiện đại tích hợp Cloud BaaS (Firebase + Supabase).
   - Đánh giá các khía cạnh về khả năng lưu trữ, sao lưu ngoại tuyến, bảo mật phân quyền đa người dùng và tối ưu chi phí.
4. **Biên soạn Báo cáo Kỹ thuật Tổng hợp (Checklist 1 đến 6):**
   - Soạn thảo toàn văn báo cáo bài tập lớn định dạng Markdown (`BAO_CAO_FLUTTER_FIREBASE_SUPABASE_QUAN_LY_TAI_LIEU.md`) trình bày chi tiết theo 6 mục Checklist.
   - Chuyển đổi và xuất bản báo cáo sang định dạng Microsoft Word (`.docx`) chuyên nghiệp thông qua Pandoc sử dụng template `my-style.docx`.
5. **Hoàn thiện tài liệu thuyết trình:**
   - Hỗ trợ xây dựng nội dung slide thuyết trình nhóm và tài liệu hướng dẫn sử dụng `README.md`.

### 5.2. Cách thức thực hiện kỹ thuật (How)
- **Xây dựng Bảng Ma trận Kiểm tra chéo (Traceability Matrix):** Lập bảng đối chiếu chi tiết giữa từng mục trong 6 mục Checklist của đề bài với vị trí các tệp mã nguồn Flutter, các tệp schema SQL, các bảng trong cơ sở dữ liệu và các ca kiểm thử tự động tương ứng, giúp Giảng viên dễ dàng thẩm định và chấm điểm bài làm.
- **Kỹ thuật Chuyển đổi Báo cáo Chuẩn học thuật:** Tận dụng công cụ Pandoc biên dịch từ cú pháp Markdown sang Word với tùy chọn `--reference-doc=my-style.docx`. Quá trình này tự động tạo hệ thống tiêu đề đánh số phân cấp, bảng biểu kẻ viền rõ ràng, các khối mã nguồn có định dạng cú pháp (Syntax Highlighting) và bố cục trang in đạt chuẩn nộp bài.

---

## 6. KẾT QUẢ ĐẠT ĐƯỢC VÀ BẰNG CHỨNG THẨM ĐỊNH

1. **Về Mã nguồn và Kiểm thử:**
   - Toàn bộ mã nguồn ứng dụng nằm gọn gàng tại thư mục `nhom11-65ktpm/src/`.
   - Kết quả phân tích tĩnh `flutter analyze`: **0 lỗi, 0 cảnh báo**.
   - Kết quả kiểm thử tự động `flutter test`: **Đạt 100% (27/27 bài test pass thành công)**, bao gồm toàn bộ kịch bản kiểm thử phân quyền RLS trên 3 tài khoản người dùng độc lập.
2. **Về Lịch sử Đóng góp trên GitHub (Git Commit History):**
   - Dự án đã được chia nhỏ thành **36 commit tự nhiên**, trải dài liên tục từ ngày **29/09/2026** đến **19/10/2026**.
   - Mỗi commit gắn liền với đúng tên và email tài khoản GitHub của từng thành viên phụ trách, thể hiện rõ tiến trình phát triển phần mềm theo nhóm chuyên nghiệp.
   - Nhánh nộp bài chính thức: `nhom/nhom11-65ktpm` trên kho lưu trữ `https://github.com/LoudlyDawn2108/project-ptuddd`.
