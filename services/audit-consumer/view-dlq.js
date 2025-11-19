const { Kafka } = require('kafkajs');

const brokers = process.env.KAFKA_BROKERS
  ? process.env.KAFKA_BROKERS.split(',')
  : ['localhost:9092'];

const kafka = new Kafka({
  clientId: 'dlq-viewer',
  brokers,
});

const consumer = kafka.consumer({ groupId: 'dlq-viewer-group' });

async function viewDLQ() {
  await consumer.connect();
  await consumer.subscribe({ topic: 'order.audit.dlq', fromBeginning: true });

  console.log('=== DLQ Viewer Started ===');
  console.log('Reading messages from order.audit.dlq...\n');

  await consumer.run({
    eachMessage: async ({ message }) => {
      const event = JSON.parse(message.value.toString());
      console.log('--- DLQ Message ---');
      console.log('Order ID:', event.orderId);
      console.log('User ID:', event.userId);
      console.log('Items:', JSON.stringify(event.items, null, 2));
      console.log('Created At:', event.createdAt);
      console.log('Full Payload:', JSON.stringify(event, null, 2));
      console.log('---\n');
    },
  });
}

process.on('SIGINT', async () => {
  console.log('\nShutting down DLQ viewer...');
  await consumer.disconnect();
  process.exit(0);
});

viewDLQ().catch(async (error) => {
  console.error('Error in DLQ viewer:', error);
  await consumer.disconnect();
  process.exit(1);
});

