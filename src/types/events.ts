export interface OrderCreatedEvent {
  orderId: number;
  userId: number;
  items: Array<{
    name: string;
    price: number;
    quantity: number;
  }>;
  createdAt: string;
}

