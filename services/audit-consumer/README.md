# Audit Consumer Service

## 功能概述

Audit Consumer 是一个 Kafka 消费者服务，用于处理订单事件并记录审计日志。

## 事件流

### 1. order.events 事件流

```
API Service → Kafka (order.events) → Audit Consumer → Database (AuditLog)
```

**流程：**
1. API 创建订单后发送 `OrderCreatedEvent` 到 `order.events` topic
2. Audit Consumer 消费消息
3. 写入审计日志到数据库

### 2. 死信队列 (order.audit.dlq)

```
处理失败 → 重试3次 → 仍失败 → 发送到 order.audit.dlq
```

**重试机制：**
- 默认重试 3 次
- 每次重试间隔递增（1秒、2秒、3秒）
- 所有重试失败后发送到死信队列

## 使用方法

### 启动消费者

```bash
cd services/audit-consumer
npm start
```

### 查看死信队列

```bash
cd services/audit-consumer
npm run view-dlq
```

或者直接使用：

```bash
node view-dlq.js
```

## Topics

- `order.events`: 订单事件流
- `order.audit.dlq`: 死信队列（处理失败的消息）

## 环境变量

- `DATABASE_URL`: PostgreSQL 连接字符串
- `KAFKA_BROKERS`: Kafka broker 地址（默认: localhost:9092）

