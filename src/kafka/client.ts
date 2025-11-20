import { Kafka } from 'kafkajs';

const kafkaBrokers =
  process.env.KAFKA_BROKERS ||
  process.env.KAFKA_BROKER ||
  'localhost:9092';

const kafka = new Kafka({
  clientId: 'order-api',
  brokers: kafkaBrokers.split(','),
});

export const producer = kafka.producer();

export async function connectKafka() {
  await producer.connect();
}

export async function disconnectKafka() {
  await producer.disconnect();
}

export const TOPICS = {
  ORDER_EVENTS: 'order.events',
  ORDER_AUDIT: 'order.audit',
} as const;

