# SKILL

## Prompt

Khi bắt đầu hỏi với Agent cần sử dụng :

```text
Tạo tài liệu hướng dẫn sử dụng theo tiêu chuẩn theo ngôn ngữ lập trình là Go
① DEFINE   — Định nghĩa, phân biệt, actors, invariants, failure modes
② GRAPH    — Diagrams minh hoạ (ASCII)
③ CODE     — Code examples với annotated comments ( từ cơ bản đến nâng cao ), chi tiết, trực quan và dễ hiểu, từ đơn giản đến chuyên sâu, phức tạp, từ kỹ thuật đơn lẻ cho đến kết hợp với nhiều kỹ thuật phức tạp( ví dụ, tôi sử dụng kỹ thuật Pipeline trong Go, cơ bản hướng dẫn tôi kỹ thuật pipeline thuần túy, sau đó, chuyên sâu hơn, kết hợp pipeline trong ETL pipeline như Pipeline + GORM: Extract (query) → Transform (goroutine) → Load (batch insert). Một ví dụ khác, áp dụng Event-driven pipeline , ThreeDotsLabs/watermill` : Message-driven architecture — Kafka, AMQP, GoChannel). Đặc biệt, example có sự kết hợp với các recommend là tuyệt vời. Trước mỗi example cần introduce sắp làm gì, cần gì, có gì, mục tiêu đạt được là gì. Sau mỗi example, đã đạt được gì,  những lưu ý gì khi sử dụng.
④ PITFALLS — Lỗi thường gặp + cách fix
⑤ REF      — Tham khảo
⑥ RECOMMEND: Liên quan đến những công nghệ, thư viện, modules lân cận, tính năng, tính năng mở rộng và gợi ý đề xuất
```
