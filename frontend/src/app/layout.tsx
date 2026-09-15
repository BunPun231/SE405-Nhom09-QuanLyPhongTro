export function AppLayout() {
  return (
    <main className="min-h-screen bg-gradient-to-b from-brand-sand via-white to-brand-sand text-brand-ink">
      <div className="mx-auto max-w-5xl px-4 py-10 sm:px-6 lg:px-8">
        <header className="mb-8 rounded-2xl border border-brand-warm/40 bg-white/80 p-6 shadow-sm backdrop-blur">
          <p className="text-sm font-medium uppercase tracking-[0.2em] text-brand-deep/80">Smart Boarding House</p>
          <h1 className="mt-2 font-display text-3xl font-bold text-brand-ink sm:text-4xl">Rental Management SaaS</h1>
          <p className="mt-3 max-w-2xl text-sm text-slate-600">
            Project scaffold is ready. Continue by implementing domain modules: tenant, motel, contract, billing, maintenance, and notifications.
          </p>
        </header>

        <section className="grid gap-4 sm:grid-cols-2">
          <article className="rounded-xl border border-slate-200 bg-white p-5">
            <h2 className="font-display text-xl">Backend</h2>
            <p className="mt-2 text-sm text-slate-600">Spring Boot modular monolith scaffolded with multi-tenant context, Flyway, Redis, and OpenAPI.</p>
          </article>
          <article className="rounded-xl border border-slate-200 bg-white p-5">
            <h2 className="font-display text-xl">Frontend</h2>
            <p className="mt-2 text-sm text-slate-600">React + Vite + Tailwind + Zustand + TanStack Query with PWA-ready config.</p>
          </article>
        </section>
      </div>
    </main>
  );
}
