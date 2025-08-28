import 'package:flutter_test/flutter_test.dart';
import 'package:champions_gym_app/shared/utils/avatar_utils.dart';

void main() {
  group('AvatarUtils', () {
    group('getInitials', () {
      test('should return first and last name initials for full name', () {
        expect(AvatarUtils.getInitials('John Doe', 'john@example.com'), 'JD');
        expect(AvatarUtils.getInitials('Mary Jane Smith', 'mary@example.com'),
            'MS');
      });

      test('should return first two letters for single name', () {
        expect(AvatarUtils.getInitials('John', 'john@example.com'), 'JO');
        expect(AvatarUtils.getInitials('A', 'a@example.com'), 'A');
      });

      test('should fallback to email when name is null or empty', () {
        expect(AvatarUtils.getInitials(null, 'john@example.com'), 'JO');
        expect(AvatarUtils.getInitials('', 'john@example.com'), 'JO');
        expect(AvatarUtils.getInitials(' ', 'john@example.com'), 'JO');
      });

      test('should return first two letters of email username', () {
        expect(AvatarUtils.getInitials(null, 'john.doe@example.com'), 'JO');
        expect(AvatarUtils.getInitials(null, 'a@example.com'), 'A');
      });

      test('should return default "U" when both name and email are null/empty',
          () {
        expect(AvatarUtils.getInitials(null, null), 'U');
        expect(AvatarUtils.getInitials('', ''), 'U');
        expect(AvatarUtils.getInitials(null, ''), 'U');
        expect(AvatarUtils.getInitials('', null), 'U');
      });
    });

    group('getAvatarBackgroundColor', () {
      test('should return consistent color for same input', () {
        final color1 = AvatarUtils.getAvatarBackgroundColor(
            'John Doe', 'john@example.com');
        final color2 = AvatarUtils.getAvatarBackgroundColor(
            'John Doe', 'john@example.com');
        expect(color1, equals(color2));
      });

      test('should return different colors for different inputs', () {
        final color1 = AvatarUtils.getAvatarBackgroundColor(
            'John Doe', 'john@example.com');
        final color2 = AvatarUtils.getAvatarBackgroundColor(
            'Jane Smith', 'jane@example.com');
        expect(color1, isNot(equals(color2)));
      });

      test('should handle null inputs gracefully', () {
        expect(() => AvatarUtils.getAvatarBackgroundColor(null, null),
            returnsNormally);
        expect(() => AvatarUtils.getAvatarBackgroundColor('John', null),
            returnsNormally);
        expect(
            () =>
                AvatarUtils.getAvatarBackgroundColor(null, 'john@example.com'),
            returnsNormally);
      });
    });
  });
}
