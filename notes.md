# 数据库性能分析笔记

## 索引配置

### Order 表索引

1. **userId 索引** (`Order_userId_idx`)
   - 类型: B-tree
   - 用途: 优化按用户查询订单的性能
   - 迁移: `20251118061533_add_user_id_index`

2. **createdAt 索引** (`Order_createdAt_idx`)
   - 类型: B-tree
   - 用途: 优化按创建时间排序的查询性能
   - 迁移: `20251118063847_add_created_at_index`

## EXPLAIN ANALYZE 查询分析

### 查询 1: 按 userId 查询并排序

```sql
EXPLAIN ANALYZE SELECT * FROM "Order" WHERE "userId" = 1 ORDER BY "createdAt" DESC;
```

**查询计划：**
```
Sort  (cost=14.91..14.93 rows=9 width=16) (actual time=0.017..0.018 rows=0 loops=1)
   Sort Key: "createdAt" DESC
   Sort Method: quicksort  Memory: 25kB
   ->  Bitmap Heap Scan on "Order"  (cost=4.22..14.76 rows=9 width=16) (actual time=0.003..0.003 rows=0 loops=1)
         Recheck Cond: ("userId" = 1)
         ->  Bitmap Index Scan on "Order_userId_idx"  (cost=0.00..4.22 rows=9 width=0) (actual time=0.001..0.001 rows=0 loops=1)
               Index Cond: ("userId" = 1)
 Planning Time: 0.220 ms
 Execution Time: 0.049 ms
```

**分析：**
- ✅ 使用了 `userId` 索引（Bitmap Index Scan）
- ✅ 执行时间: 0.049 ms
- ⚠️ 排序操作：使用 quicksort（因为数据量小，PostgreSQL 选择内存排序）

### 查询 2: 按 createdAt 排序（使用索引）

```sql
EXPLAIN ANALYZE SELECT * FROM "Order" ORDER BY "createdAt" DESC LIMIT 10;
```

**查询计划：**
```
Limit  (cost=0.15..0.54 rows=10 width=16) (actual time=0.003..0.003 rows=0 loops=1)
   ->  Index Scan Backward using "Order_createdAt_idx" on "Order"  (cost=0.15..71.90 rows=1850 width=16) (actual time=0.002..0.003 rows=0 loops=1)
 Planning Time: 0.174 ms
 Execution Time: 0.015 ms
```

**分析：**
- ✅ 直接使用 `createdAt` 索引（Index Scan Backward）
- ✅ 执行时间: 0.015 ms（比查询1更快）
- ✅ 无需额外排序操作，索引已按时间排序

## 性能对比

| 查询类型 | 索引使用 | 执行时间 | 说明 |
|---------|---------|---------|------|
| WHERE userId + ORDER BY createdAt | userId 索引 + 排序 | 0.049 ms | 使用 userId 索引过滤，然后排序 |
| ORDER BY createdAt LIMIT | createdAt 索引 | 0.015 ms | 直接使用索引，无需排序 |

## 结论

1. **userId 索引**：有效优化了按用户查询的性能
2. **createdAt 索引**：显著提升了按时间排序的查询性能，特别是配合 LIMIT 使用时
3. **组合查询**：当同时使用 WHERE 和 ORDER BY 时，PostgreSQL 会优先使用 WHERE 条件的索引，然后对结果进行排序

## 建议

- 对于频繁按时间排序的查询，`createdAt` 索引非常有效
- 对于按用户查询订单的场景，`userId` 索引是必需的
- 当数据量增大时，索引的优势会更加明显

