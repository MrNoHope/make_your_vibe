# Comment cho phần Auth, Sound Effects và Widgets phụ

## Commit message ngắn

feat(auth-sound): add auth flow, sound effects screen and reusable widgets

## Commit message chi tiết

Hoàn thiện các phần giao diện và widget phụ cho ứng dụng Make Your Vibe, bao gồm màn hình xác thực người dùng, màn hình hiệu ứng âm thanh môi trường và các widget tái sử dụng trong app.

### 1. Auth / Login / Register

- Xây dựng `AuthScreen` để quản lý luồng xác thực trong ứng dụng.
- Thêm màn hình đăng nhập với email, mật khẩu, trạng thái loading và thông báo lỗi khi đăng nhập thất bại.
- Thêm màn hình đăng ký tài khoản với các trường tên tài khoản, mã số sinh viên, email và mật khẩu.
- Thêm checkbox đồng ý điều khoản dịch vụ trước khi đăng ký.
- Thêm luồng quên mật khẩu dạng mock, cho phép nhập email và chuyển sang bước xác nhận mã OTP.
- Sử dụng `AnimatedSwitcher` để chuyển đổi mượt giữa các màn hình Login, Register và Forgot Password.

File liên quan:
- `lib/screens/auth/auth_screen.dart`
- `lib/widgets/auth_widgets.dart`

### 2. Sound Effects screen

- Xây dựng màn hình `SoundEffectsPage` để hiển thị danh sách hiệu ứng âm thanh môi trường.
- Hiển thị số lượng ambient sound đang được bật bằng `StatusPill`.
- Thêm `AmbientBanner` để tóm tắt các âm nền đang hoạt động và mở nhanh bộ trộn âm thanh.
- Hiển thị các hiệu ứng môi trường bằng dạng grid 2 cột.
- Cho phép người dùng bật/tắt từng ambient layer thông qua `controller.toggleAmbient(layer)`.

File liên quan:
- `lib/screens/sound/sound_effects_page.dart`
- `lib/widgets/ambient_widgets.dart`

### 3. Các widget hiển thị phụ

- Tạo các widget dùng lại cho màn hình xác thực gồm `AuthLayout`, `AppTextField` và `PrimaryButton`.
- Tạo các widget ambient như `AmbientTile`, `AmbientCompactTile`, `AmbientBanner` và `MixerRow` để hỗ trợ hiển thị và điều chỉnh âm nền.
- Tạo các widget bài hát như `CoverArt`, `SongCard` và `SongListTile` để hiển thị ảnh bìa, thông tin bài hát và trạng thái yêu thích.
- Tạo `MiniPlayer` để hiển thị bài hát đang phát, trạng thái ambient hiện tại và nút play/pause.
- Tách các thành phần giao diện thành widget riêng giúp code dễ đọc, dễ tái sử dụng và dễ bảo trì hơn.

File liên quan:
- `lib/widgets/auth_widgets.dart`
- `lib/widgets/ambient_widgets.dart`
- `lib/widgets/song_widgets.dart`
- `lib/widgets/mini_player.dart`

### 4. Test cơ bản

- Giữ cấu trúc test widget cơ bản trong `test/widget_test.dart`.
- Tạo placeholder test để dự án có sẵn nơi mở rộng kiểm thử trong các bước tiếp theo.

File liên quan:
- `test/widget_test.dart`

## Nội dung comment có thể dán vào Git commit

feat(auth-sound): add auth screens, sound effects page and reusable widgets

- Add AuthScreen with login, register and forgot password mock flow.
- Add reusable auth widgets: AuthLayout, AppTextField and PrimaryButton.
- Add SoundEffectsPage to display and toggle ambient sound layers.
- Add ambient widgets for tiles, banner and mixer rows.
- Add song display widgets and mini player UI.
- Keep placeholder widget test for future test expansion.

## Comment tiếng Việt ngắn để ghi trong báo cáo hoặc mô tả pull request

Phần này tập trung hoàn thiện giao diện xác thực người dùng, màn hình hiệu ứng âm thanh và các widget hiển thị phụ của ứng dụng Make Your Vibe. Nhóm đã xây dựng luồng đăng nhập, đăng ký và quên mật khẩu dạng mock; đồng thời bổ sung màn hình Sound Effects để người dùng bật/tắt các âm thanh môi trường. Ngoài ra, các thành phần giao diện như ô nhập liệu, nút chính, thẻ ambient, thẻ bài hát và mini player được tách thành widget riêng nhằm giúp mã nguồn gọn gàng, dễ tái sử dụng và thuận tiện bảo trì.
