const { Kafka } = require('kafkajs');

const brokers = process.env.KAFKA_BROKERS
  ? process.env.KAFKA_BROKERS.split(',').map(b => b.trim())
  : ['localhost:9092'];

console.log('KAFKA_BROKERS env:', process.env.KAFKA_BROKERS);
console.log('Parsed brokers:', brokers);

const kafka = new Kafka({
  clientId: 'topic-init',
  brokers,
});

const admin = kafka.admin();

async function waitForKafka(maxRetries = 10) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      if (!admin) {
        throw new Error('Admin client not initialized');
      }
      await admin.connect();
      await admin.listTopics();
      console.log('Kafka is ready');
      return true;
    } catch (error) {
      if (i < maxRetries - 1) {
        console.log(`Waiting for Kafka... (${i + 1}/${maxRetries})`);
        try {
          await admin.disconnect();
        } catch (e) {
          // Ignore disconnect errors
        }
        await new Promise((resolve) => setTimeout(resolve, 2000));
      } else {
        throw error;
      }
    }
  }
  throw new Error('Kafka is not available');
}

async function createTopics() {
  await waitForKafka();

  const topics = [
    {
      topic: 'order.events',
      numPartitions: 1,
      replicationFactor: 1,
    },
    {
      topic: 'order.audit.dlq',
      numPartitions: 1,
      replicationFactor: 1,
    },
  ];

  try {
    await admin.createTopics({
      topics,
      waitForLeaders: true,
    });
    console.log('Topics created successfully');
  } catch (error) {
    if (error.message.includes('already exists') || error.message.includes('TopicExistsException')) {
      console.log('Topics already exist');
    } else {
      console.error('Error creating topics:', error.message);
    }
  } finally {
    await admin.disconnect();
  }
}

createTopics().catch((error) => {
  console.error('Failed to create topics:', error);
  process.exit(1);
});

