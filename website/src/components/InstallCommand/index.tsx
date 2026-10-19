import {useState, type ReactNode} from 'react';
import styles from './styles.module.css';

export const INSTALL_COMMAND =
  'curl -fsSL https://raw.githubusercontent.com/carlosmedina06/mirro/main/install.sh | bash';

/** El comando de instalación con botón para copiarlo. */
export default function InstallCommand(): ReactNode {
  const [copied, setCopied] = useState(false);

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(INSTALL_COMMAND);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // El navegador no permitió copiar; el texto sigue seleccionable
    }
  };

  return (
    <div className={styles.box}>
      <code className={styles.command}>
        <span className={styles.prompt}>$</span>
        {INSTALL_COMMAND}
      </code>
      <button type="button" className={styles.copy} onClick={copy} aria-label="Copiar comando">
        {copied ? 'Copiado ✓' : 'Copiar'}
      </button>
    </div>
  );
}
