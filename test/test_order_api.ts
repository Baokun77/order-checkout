import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const API_URL = 'http://localhost:3000';

async function testCreateOrder() {
  console.log('=== 测试 1: 多 item 正常创建 ===');
  try {
    const user = await prisma.user.create({
      data: { email: `test-${Date.now()}@example.com` },
    });
    console.log(`创建用户: ${user.id}`);

    const response = await fetch(`${API_URL}/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: user.id,
        items: [
          { name: 'Item 1', price: 10.5, quantity: 2 },
          { name: 'Item 2', price: 20.0, quantity: 1 },
          { name: 'Item 3', price: 5.75, quantity: 3 },
        ],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`API 返回错误: ${response.status} - ${errorText}`);
    }

    const result = await response.json();
    console.log('订单创建成功:', result);

    const order = await prisma.order.findUnique({
      where: { id: result.id },
      include: { items: true },
    });
    console.log(`订单包含 ${order?.items.length} 个 items`);
    console.log('✓ 测试通过\n');
  } catch (error) {
    console.error('✗ 测试失败:', error);
  }
}

async function testInvalidData() {
  console.log('=== 测试 2: 字段不合法（price 为字符串）===');
  try {
    const user = await prisma.user.create({
      data: { email: `test-invalid-${Date.now()}@example.com` },
    });
    console.log(`创建用户: ${user.id}`);

    const orderCountBefore = await prisma.order.count();
    const orderItemCountBefore = await prisma.orderItem.count();
    console.log(`测试前: Order=${orderCountBefore}, OrderItem=${orderItemCountBefore}`);

    const response = await fetch(`${API_URL}/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: user.id,
        items: [
          { name: 'Valid Item', price: 10.5, quantity: 1 },
          { name: 'Invalid Item', price: 'invalid' as any, quantity: 2 },
        ],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.log('API 返回错误（预期行为）:', response.status, errorText);
    } else {
      const result = await response.json();
      console.log('响应:', result);
    }

    const orderCountAfter = await prisma.order.count();
    const orderItemCountAfter = await prisma.orderItem.count();
    console.log(`测试后: Order=${orderCountAfter}, OrderItem=${orderItemCountAfter}`);

    if (orderCountAfter === orderCountBefore && orderItemCountAfter === orderItemCountBefore) {
      console.log('✓ 事务已回滚，数据库中没有残余数据\n');
    } else {
      console.log('✗ 事务未回滚，数据库中有残余数据！');
      console.log(`Order 增加: ${orderCountAfter - orderCountBefore}`);
      console.log(`OrderItem 增加: ${orderItemCountAfter - orderItemCountBefore}\n`);
    }
  } catch (error) {
    console.log('✓ 捕获到错误（预期行为）:', error);
    const orderCountAfter = await prisma.order.count();
    const orderItemCountAfter = await prisma.orderItem.count();
    console.log(`最终: Order=${orderCountAfter}, OrderItem=${orderItemCountAfter}\n`);
  }
}

async function cleanup() {
  console.log('=== 清理测试数据 ===');
  await prisma.orderItem.deleteMany({});
  await prisma.order.deleteMany({});
  await prisma.user.deleteMany({});
  console.log('✓ 清理完成\n');
}

async function main() {
  try {
    await cleanup();
    await testCreateOrder();
    await testInvalidData();
  } finally {
    await prisma.$disconnect();
  }
}

main().catch(console.error);

