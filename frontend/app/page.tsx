import Image from "next/image";

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-zinc-50 to-white dark:from-black dark:to-zinc-950">
      <header className="border-b border-zinc-200 dark:border-zinc-800 bg-white/80 dark:bg-black/80 backdrop-blur-sm sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <h1 className="text-3xl font-bold text-black dark:text-white">
            Lukest<span className="text-blue-600">AWS</span>
          </h1>
          <nav className="hidden md:flex gap-8">
            <a href="#" className="text-zinc-600 hover:text-black dark:text-zinc-400 dark:hover:text-white">
              Services
            </a>
            <a href="#" className="text-zinc-600 hover:text-black dark:text-zinc-400 dark:hover:text-white">
              Free Audit
            </a>
          </nav>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-6 py-16">
        <div className="text-center mb-16">
          <h2 className="text-5xl md:text-6xl font-bold tracking-tight text-black dark:text-white mb-6">
            From Uber Driver to AWS Savings Expert
          </h2>
          <p className="text-2xl text-zinc-600 dark:text-zinc-400 max-w-3xl mx-auto mb-8">
            Helping UK small businesses cut AWS bills 30–70% – no lock-ins, no fluff
          </p>
          <p className="text-xl text-zinc-500 dark:text-zinc-400 max-w-2xl mx-auto">
            Real-world experience building & optimising AWS infrastructure – now helping you do the same.
          </p>
        </div>

        {/* Savings services grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {[
            {
              title: "EC2 Right-Sizing & Spot Instances",
              desc: "Stop paying for idle resources. Typical savings: 50–70%",
              savings: "50–70%",
            },
            {
              title: "S3 Intelligent Tiering & Glacier",
              desc: "Automatic cold data movement. Cut storage costs in half",
              savings: "40–60%",
            },
            {
              title: "Reserved Instances & Savings Plans",
              desc: "Smart commitments for predictable savings",
              savings: "30–60%",
            },
          ].map((item, i) => (
            <div
              key={i}
              className="bg-white dark:bg-zinc-900 rounded-xl overflow-hidden shadow-lg border border-zinc-200 dark:border-zinc-800 flex flex-col"
            >
              <div className="h-48 bg-gradient-to-br from-blue-600 to-indigo-600 flex items-center justify-center">
                <span className="text-white text-5xl font-bold">{item.savings}</span>
              </div>
              <div className="p-6 flex flex-col flex-grow">
                <h3 className="text-xl font-semibold mb-3">{item.title}</h3>
                <p className="text-zinc-600 dark:text-zinc-400 mb-6 flex-grow">{item.desc}</p>
                <button className="w-full bg-black text-white dark:bg-white dark:text-black py-3 rounded-lg font-medium hover:opacity-90 transition">
                  Get Free Audit
                </button>
              </div>
            </div>
          ))}
        </div>

        {/* Strong CTA */}
        <div className="text-center mt-16 py-12 bg-zinc-100 dark:bg-zinc-900 rounded-2xl">
          <h3 className="text-3xl font-bold mb-6">Ready to Stop Overpaying AWS?</h3>
          <p className="text-lg text-zinc-600 dark:text-zinc-400 mb-8 max-w-2xl mx-auto">
            Book a 30-min free bill health check. Honest feedback, real savings opportunities – no pressure.
          </p>
          <button className="bg-blue-600 text-white px-10 py-4 rounded-full font-medium text-lg hover:bg-blue-700 transition">
            Claim Free Audit Now
          </button>
        </div>
      </main>

      <footer className="border-t border-zinc-200 dark:border-zinc-800 py-12 text-center text-zinc-500 dark:text-zinc-400">
        <p>© 2026 LukestAWS – AWS Cost Optimisation & Reliability for UK SMBs</p>
        <p className="mt-2 text-sm">
          Built & deployed on AWS Fargate – proof that we practice what we preach
        </p>
      </footer>
    </div>
  );
}