import { Kafka } from 'kafkajs';

const kafka = new Kafka({
  clientId: 'order-api',
  brokers: (process.env.KAFKA_BROKERS || 'localhost:9092').split(','),
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

