import type {ReactNode} from 'react';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';
import InstallCommand from '@site/src/components/InstallCommand';
import MacWindow from '@site/src/components/MacWindow';
import styles from './index.module.css';

type Feature = {title: string; text: string; icon: ReactNode};

// Iconos de trazo simple (24x24), heredan el color del texto
const svg = (d: ReactNode) => (
  <svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor"
       strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
    {d}
  </svg>
);

const FEATURES: Feature[] = [
  {
    title: 'Un clic para duplicar',
    text: 'Ve y usa la pantalla del teléfono en una ventana de tu Mac, con teclado, ratón y audio.',
    icon: svg(<><rect x="6" y="2.5" width="12" height="19" rx="2.5" /><path d="M10 18.5h4" /></>),
  },
  {
    title: 'Varios a la vez',
    text: 'Duplica todos tus dispositivos con «Duplicar todos» y detenlos con un solo clic.',
    icon: svg(<><rect x="3" y="4" width="9" height="15" rx="2" /><rect x="12" y="6" width="9" height="15" rx="2" /></>),
  },
  {
    title: 'USB o WiFi',
    text: 'Pasa un teléfono USB a WiFi automáticamente, o conéctate escribiendo su IP.',
    icon: svg(<><path d="M2 8.5a15 15 0 0 1 20 0" /><path d="M5.5 12a10 10 0 0 1 13 0" /><path d="M9 15.5a5 5 0 0 1 6 0" /><circle cx="12" cy="19" r="0.8" fill="currentColor" /></>),
  },
  {
    title: 'En la barra de estado',
    text: 'Siempre a mano. El icono te muestra si hay algo duplicándose y cuántos dispositivos.',
    icon: svg(<><rect x="2.5" y="4" width="19" height="16" rx="2.5" /><path d="M2.5 8.5h19" /></>),
  },
  {
    title: 'Nada que instalar',
    text: 'scrcpy y adb vienen dentro de la app. Si ya tienes adb (Android Studio), Mirro usa el tuyo.',
    icon: svg(<><path d="M12 3v12" /><path d="m7 10 5 5 5-5" /><path d="M4 20h16" /></>),
  },
  {
    title: 'Nativa y ligera',
    text: 'Escrita en Swift y SwiftUI. Universal para Apple Silicon e Intel, con modo claro y oscuro.',
    icon: svg(<><path d="M13 2 4 14h7l-1 8 9-12h-7z" /></>),
  },
];

const STEPS = [
  {title: 'Instala Mirro', text: 'Con el comando de arriba o descargando el .zip desde GitHub.'},
  {title: 'Activa la depuración USB', text: 'Mirro te guía paso a paso la primera vez que la abres.'},
  {title: 'Conecta y duplica', text: 'Conecta el teléfono y pulsa «Duplicar». Eso es todo.'},
];

function Hero() {
  return (
    <header className={styles.hero}>
      <div className="container">
        <img className={styles.logo} src={useBaseUrl('/img/icon.png')} alt="" width={128} height={128} />
        <Heading as="h1" className={styles.title}>Mirro</Heading>
        <p className={styles.tagline}>
          Duplica y controla tus teléfonos Android desde la barra de estado de tu Mac.
        </p>
        <InstallCommand />
        <div className={styles.buttons}>
          <Link className="button button--primary button--lg" to="/docs/instalacion">
            Empezar
          </Link>
          <Link className="button button--secondary button--outline button--lg" href="https://github.com/carlosmedina06/mirro">
            Ver en GitHub
          </Link>
        </div>
        <p className={styles.meta}>macOS 13 o posterior · Apple Silicon e Intel · Gratis y open source</p>
      </div>
    </header>
  );
}

export default function Home(): ReactNode {
  return (
    <Layout
      title="Duplica tu Android en la Mac"
      description="Mirro es una app gratuita para macOS que duplica y controla tus teléfonos Android desde la barra de estado, usando scrcpy.">
      <Hero />
      <main>
        <section className={styles.screenshot}>
          <div className="container">
            <MacWindow name="devices" alt="Ventana de Mirro con la lista de dispositivos conectados" width={760} />
          </div>
        </section>

        <section className={styles.section}>
          <div className="container">
            <Heading as="h2" className={styles.sectionTitle}>Todo lo que necesitas, nada más</Heading>
            <div className={styles.features}>
              {FEATURES.map((f) => (
                <div key={f.title} className={styles.feature}>
                  <div className={styles.featureIcon}>{f.icon}</div>
                  <Heading as="h3">{f.title}</Heading>
                  <p>{f.text}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className={`${styles.section} ${styles.alt}`}>
          <div className="container">
            <Heading as="h2" className={styles.sectionTitle}>Listo en un minuto</Heading>
            <ol className={styles.steps}>
              {STEPS.map((s, i) => (
                <li key={s.title} className={styles.step}>
                  <span className={styles.stepNumber}>{i + 1}</span>
                  <Heading as="h3">{s.title}</Heading>
                  <p>{s.text}</p>
                </li>
              ))}
            </ol>
          </div>
        </section>

        <section className={styles.section}>
          <div className={`container ${styles.credits}`}>
            <p>
              Mirro está construida sobre{' '}
              <Link href="https://github.com/Genymobile/scrcpy">scrcpy</Link>, el excelente proyecto
              open source de Genymobile, que se incluye sin modificaciones bajo la licencia Apache 2.0.
            </p>
          </div>
        </section>
      </main>
    </Layout>
  );
}
