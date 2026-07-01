# Khánh

Branch: feature/khanh-backend-user-data

Phần phụ trách:
- Backend tài khoản
- Lưu thông tin người dùng
- Lưu bài hát đã thích
- Lưu playlist
- Lưu vibe preset
- Chuẩn bị chuyển local backend sang Supabase/Firebase sau này

Các file chính:
- lib/services/local_backend_service.dart
- lib/services/user_data_service.dart
- lib/services/remote_backend_service.dart
- lib/models/user_profile.dart
- lib/controllers/vibe_controller.dart
- lib/screens/auth/auth_screen.dart

Code cần làm thêm:
- Tạo user_data_service.dart để quản lý favorite, playlist, vibe preset.
- Tách logic lưu user ra khỏi UI.
- Chuẩn bị interface cho backend thật.
- Không sửa UI core nếu không cần.
