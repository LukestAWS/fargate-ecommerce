import Image from "next/image";

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-zinc-50 to-white dark:from-black dark:to-zinc-950">
      <header className="border-b border-zinc-200 dark:border-zinc-800 bg-white/80 dark:bg-black/80 backdrop-blur-sm sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <h1 className="text-2xl font-bold text-black dark:text-white">
            Lukest<span className="text-blue-600">Ecom</span>
          </h1>
          <nav className="hidden md:flex gap-8">
            <a href="#" className="text-zinc-600 hover:text-black dark:text-zinc-400 dark:hover:text-white">
              Products
            </a>
            <a href="#" className="text-zinc-600 hover:text-black dark:text-zinc-400 dark:hover:text-white">
              Cart (0)
            </a>
          </nav>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-6 py-16">
        <div className="text-center mb-16">
          <h2 className="text-5xl md:text-6xl font-bold tracking-tight text-black dark:text-white mb-6">
            Modern E-commerce on AWS Fargate
          </h2>
          <p className="text-xl text-zinc-600 dark:text-zinc-400 max-w-2xl mx-auto">
            Week 6–8 Portfolio Project – Next.js Frontend + Microservices + Stripe
          </p>
        </div>

        {/* Hero / Featured Products placeholder */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {[1, 2, 3].map((i) => (
            <div key={i} className="bg-white dark:bg-zinc-900 rounded-xl overflow-hidden shadow-lg border border-zinc-200 dark:border-zinc-800">
              <div className="h-64 bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
                <span className="text-white text-6xl font-bold">Product {i}</span>
              </div>
              <div className="p-6">
                <h3 className="text-xl font-semibold mb-2">Awesome Gadget {i}</h3>
                <p className="text-zinc-600 dark:text-zinc-400 mb-4">$49.99</p>
                <button className="w-full bg-black text-white dark:bg-white dark:text-black py-3 rounded-lg font-medium hover:opacity-90 transition">
                  Add to Cart
                </button>
              </div>
            </div>
          ))}
        </div>
      </main>

      <footer className="border-t border-zinc-200 dark:border-zinc-800 py-8 text-center text-zinc-500 dark:text-zinc-400">
        <p>© 2026 LukestAWS Portfolio – Built with Next.js + AWS ECS Fargate</p>
      </footer>
    </div>
  );
}