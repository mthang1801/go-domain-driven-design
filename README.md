# **Cấu trúc thư mục**

Cấu trúc thư mục được tổ chức như sau:

project/
├── cmd/
│ └── main.go // Điểm khởi chạy ứng dụng
├── internal/
│ ├── domain/
│ │ ├── agreement/
│ │ │ ├── entities/ // Các entity (ví dụ: Agreement)
│ │ │ ├── valueobjects/ // Các value object (ví dụ: Email)
│ │ │ ├── repositories/ // Interface cho repository
│ │ │ └── services/ // Domain services (nếu cần)
│ │ └── feature_test_product/
│ │ ├── entities/
│ │ ├── valueobjects/
│ │ ├── repositories/
│ │ └── services/
│ ├── application/
│ │ ├── agreement/
│ │ │ ├── dto/ // Data Transfer Objects
│ │ │ ├── usecases/ // Các use case (ví dụ: CreateAgreement)
│ │ │ └── services/ // Application services
│ │ └── feature_test_product/
│ │ ├── dto/
│ │ ├── usecases/
│ │ └── services/
│ ├── infrastructure/
│ │ ├── agreement/
│ │ │ ├── repositories/ // Triển khai repository (ví dụ: SQL)
│ │ │ ├── orm/ // ORM (nếu dùng GORM)
│ │ │ └── events/ // Xử lý sự kiện
│ │ ├── database/ // Cấu hình database
│ │ └── telegram/ // Tích hợp dịch vụ bên ngoài
│ └── presentation/
│ ├── portal/
│ │ ├── handlers/ // Handler cho API portal
│ │ └── routes/ // Định nghĩa tuyến đường
│ ├── mobile/
│ │ ├── handlers/
│ │ └── routes/
│ ├── external/
│ │ ├── handlers/
│ │ └── routes/
│ └── presentation.go // Logic chia sẻ (nếu cần)
├── shared/
│ ├── mappers/ // Chuyển đổi giữa các tầng
│ ├── enum/ // Các enum
│ └── constant/ // Các hằng số
├── go.mod
└── go.sum
