import type {ReactNode} from 'react';
import ThemedImage from '@theme/ThemedImage';
import useBaseUrl from '@docusaurus/useBaseUrl';
import styles from './styles.module.css';

type Props = {
  /** Nombre de la captura en static/img/screenshots, sin -light/-dark */
  name: string;
  alt: string;
  title?: string;
  width?: number;
};

/** Captura de la app dentro de una ventana de macOS; cambia con el tema claro/oscuro. */
export default function MacWindow({name, alt, title = 'Mirro', width}: Props): ReactNode {
  return (
    <figure className={styles.window} style={width ? {maxWidth: width} : undefined}>
      <div className={styles.bar}>
        <span className={styles.dot} style={{background: '#ff5f57'}} />
        <span className={styles.dot} style={{background: '#febc2e'}} />
        <span className={styles.dot} style={{background: '#28c840'}} />
        <span className={styles.title}>{title}</span>
      </div>
      <ThemedImage
        alt={alt}
        className={styles.image}
        sources={{
          light: useBaseUrl(`/img/screenshots/${name}-light.png`),
          dark: useBaseUrl(`/img/screenshots/${name}-dark.png`),
        }}
      />
    </figure>
  );
}
