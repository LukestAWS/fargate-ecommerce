import Image from "next/image";

// 1. Define what a Product looks like
interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
}

async function getProducts(): Promise<Product[]> {
  // Use localhost for local dev, and the Service Discovery name for AWS later
  const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8001";
  
  try {
    const res = await fetch(`${API_URL}/products`, { 
      cache: 'no-store', // Ensures we always get fresh data
      next: { revalidate: 0 } 
    });
    
    if (!res.ok) return []; // Fallback to empty list if API is down
    return res.json();
  } catch (err) {
    console.error("Connection to Products Service failed", err);
    return [];
  }
}

export default async function Home() {
  const products = await getProducts();

  return (
    <div className="min-h-screen bg-gradient-to-b from-zinc-50 to-white dark:from-black dark:to-zinc-950">
      {/* ... (Header remains the same) ... */}

      <main className="max-w-7xl mx-auto px-6 py-16">
        <div className="text-center mb-16">
          <h2 className="text-5xl md:text-6xl font-bold tracking-tight text-black dark:text-white mb-6">
            From Uber Driver to AWS Savings Expert
          </h2>
          <p className="text-2xl text-zinc-600 dark:text-zinc-400 max-w-3xl mx-auto mb-8">
            Helping UK small businesses cut AWS bills 30–70%
          </p>
        </div>

        {/* Dynamic Products Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {products.length > 0 ? (
            products.map((item) => (
              <div
                key={item.id}
                className="bg-white dark:bg-zinc-900 rounded-xl overflow-hidden shadow-lg border border-zinc-200 dark:border-zinc-800 flex flex-col"
              >
                <div className="h-48 bg-gradient-to-br from-blue-600 to-indigo-600 flex items-center justify-center">
                  <span className="text-white text-3xl font-bold text-center px-4">
                    {item.name}
                  </span>
                </div>
                <div className="p-6 flex flex-col flex-grow">
                  <p className="text-zinc-600 dark:text-zinc-400 mb-6 flex-grow">{item.description}</p>
                  <div className="mb-4 text-blue-600 font-bold">
                    Starting from £{item.price}
                  </div>
                  <button className="w-full bg-black text-white dark:bg-white dark:text-black py-3 rounded-lg font-medium hover:opacity-90 transition">
                    Book Service
                  </button>
                </div>
              </div>
            ))
          ) : (
            <p className="col-span-3 text-center text-zinc-500 italic">
              Loading our latest consultancy packages...
            </p>
          )}
        </div>

        {/* ... (CTA and Footer remain the same) ... */}
      </main>
    </div>
  );
}