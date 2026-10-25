-- ============================================================================
-- Migration: V2__seed_places.sql
-- Description: Seed initial tourist places dataset for Da Nang City
-- Author: Smart Local Planner Team
-- Dialect: PostgreSQL 16+
-- ============================================================================

INSERT INTO places (
    name,
    description,
    category,
    address,
    latitude,
    longitude,
    price_level,
    opening_hours,
    image_url,
    average_rating,
    total_reviews
) VALUES
      (
          'Cầu Rồng (Dragon Bridge)',
          'Biểu tượng hiện đại độc đáo của Đà Nẵng bắc qua sông Hàn, có khả năng phun lửa và phun nước vào tối thứ Bảy và Chủ Nhật hàng tuần.',
          'ATTRACTION',
          'Đường Nguyễn Văn Linh, Phước Ninh, Hải Châu, Đà Nẵng',
          16.0611,
          108.2272,
          1,
          '24/7 (Phun lửa 21:00 cuối tuần)',
          'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1200&q=80',
          4.8,
          3520
      ),
      (
          'Sun World Bà Nà Hills',
          'Khu du lịch trên đỉnh núi Chúa với Cầu Vàng nổi tiếng thế giới nâng đỡ bởi đôi bàn tay khổng lồ, làng Pháp cổ kính và khí hậu 4 mùa trong 1 ngày.',
          'ATTRACTION',
          'Thôn An Sơn, Hòa Ninh, Hòa Vang, Đà Nẵng',
          15.9950,
          107.9965,
          4,
          '07:30 - 21:30',
          'https://images.unsplash.com/photo-1569154941061-e231b4725ef1?auto=format&fit=crop&w=1200&q=80',
          4.7,
          4890
      ),
      (
          'Bãi biển Mỹ Khê',
          'Một trong những bãi biển quyến rũ nhất hành tinh được Forbes vinh danh với bãi cát trắng mịn, sóng êm và làn nước trong xanh ấm áp quanh năm.',
          'BEACH',
          'Đường Võ Nguyên Giáp, Phước Mỹ, Sơn Trà, Đà Nẵng',
          16.0601,
          108.2462,
          1,
          '24/7 (Cứu hộ 05:00 - 19:00)',
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
          4.6,
          4150
      ),
      (
          'Danh thắng Ngũ Hành Sơn (Marble Mountains)',
          'Quần thể năm ngọn núi đá vôi mang tên Kim - Mộc - Thủy - Hỏa - Thổ với hệ thống hang động Huyền Không huyền bí, chùa Linh Ứng cổ và đài Vọng Giang.',
          'NATURE',
          '81 Huyền Trân Công Chúa, Hòa Hải, Ngũ Hành Sơn, Đà Nẵng',
          16.0044,
          108.2618,
          2,
          '07:00 - 17:30',
          'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1200&q=80',
          4.5,
          2840
      ),
      (
          'Chùa Linh Ứng - Bán đảo Sơn Trà',
          'Ngôi chùa thanh tịnh tọa lạc trên sườn núi Sơn Trà với tượng Phật Bà Quan Âm cao 67m hướng mắt ra biển Đông, nơi ngắm toàn cảnh vịnh Đà Nẵng tuyệt đẹp.',
          'CULTURE',
          'Bãi Bụt, Bán đảo Sơn Trà, Thọ Quang, Sơn Trà, Đà Nẵng',
          16.1001,
          108.2778,
          1,
          '06:00 - 20:30',
          'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?auto=format&fit=crop&w=1200&q=80',
          4.8,
          3120
      ),
      (
          'Bảo tàng Điêu khắc Chăm Đà Nẵng',
          'Nơi lưu giữ và trưng bày bộ sưu tập hiện vật điêu khắc văn hóa Champa lớn nhất thế giới, tọa lạc tại giao lộ trung tâm thành phố.',
          'CULTURE',
          'Số 02 đường 2 Tháng 9, Bình Hiên, Hải Châu, Đà Nẵng',
          16.0598,
          108.2234,
          2,
          '07:30 - 17:00',
          'https://images.unsplash.com/photo-1565019001391-76673bf54044?auto=format&fit=crop&w=1200&q=80',
          4.4,
          1430
      ),
      (
          'Chợ Cồn (Thiên đường ẩm thực Đà Nẵng)',
          'Khu chợ sầm uất bậc nhất trung tâm thành phố, nổi tiếng với phố ẩm thực bản địa phục vụ mì Quảng, bún mắm nêm, bánh xèo, ốc hút và đặc sản làm quà.',
          'RESTAURANT',
          '290 Hùng Vương, Vĩnh Trung, Hải Châu, Đà Nẵng',
          16.0692,
          108.2163,
          1,
          '07:00 - 19:30',
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1200&q=80',
          4.3,
          2670
      ),
      (
          'Cộng Cà Phê - Bạch Đằng',
          'Quán cà phê mang phong cách thời bao cấp độc đáo với tầm nhìn trực diện bờ sông Hàn thơ mộng, nổi tiếng với món cà phê cốt dừa trứ danh.',
          'CAFE',
          '96-98 Bạch Đằng, Hải Châu 1, Hải Châu, Đà Nẵng',
          16.0683,
          108.2238,
          2,
          '07:00 - 23:30',
          'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=1200&q=80',
          4.5,
          1890
      );
