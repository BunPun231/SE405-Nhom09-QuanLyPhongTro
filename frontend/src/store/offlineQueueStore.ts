import { create } from "zustand";

type QueueItem = {
  id: string;
  payload: unknown;
};

type OfflineQueueState = {
  queue: QueueItem[];
  enqueue: (item: QueueItem) => void;
  dequeue: () => void;
};

export const useOfflineQueueStore = create<OfflineQueueState>((set) => ({
  queue: [],
  enqueue: (item) => set((state) => ({ queue: [...state.queue, item] })),
  dequeue: () => set((state) => ({ queue: state.queue.slice(1) }))
}));
