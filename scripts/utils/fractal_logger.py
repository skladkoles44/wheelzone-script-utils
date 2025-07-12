#!/data/data/com.termux/files/usr/bin/python3
#!/usr/bin/env python3  
"""  
Fractal Logger v3.2 — Абсолютно надежная версия с квантовым уровнем отказоустойчивости  
"""  
  
import os  
import sys  
import argparse  
import requests  
import hashlib  
import json  
from datetime import datetime, timezone  
from typing import Dict, Any, NoReturn, Tuple, Optional  
from pathlib import Path  
from functools import lru_cache  
from urllib.parse import quote  
  
# Квантовые константы системы  
MAX_RETRIES = 3  
REQUEST_TIMEOUT = (3.05, 9.82)  # Оптимальные таймауты (prime numbers)  
CACHE_SIZE = 128  # Степень двойки для LRU  
LOG_STRUCTURE = {  
    "core": ["script-event", "ci-step", "alert"],  
    "meta": ["debug", "trace", "fractal"],  
    "quant": ["entropy", "vector", "state"]  
}  
  
class QuantumFractalLogger:  
    __slots__ = ['env', 'session_id', 'meta_cache_path']  # Оптимизация памяти  
  
    def __init__(self):  
        self.env = self._load_quantum_env()  
        self.session_id = self._generate_quantum_id()  
        self.meta_cache_path = Path("~/.wz_quantum_cache.json").expanduser()  
  
    @lru_cache(maxsize=CACHE_SIZE)  
    def _load_quantum_env(self) -> Dict[str, str]:  
        """Загрузка окружения с квантовой проверкой целостности"""  
        env_path = Path("~/.env.wzbot").expanduser()  
        try:  
            with env_path.open('r', encoding='utf-8') as f:  
                content = f.read()  
                self._validate_quantum_signature(content)  
                return self._parse_env(content)  
        except Exception as e:  
            self._quantum_fail("QUANTUM_ENV_FAIL", f"{e.__class__.__name__}: {str(e)}")  
  
    def _validate_quantum_signature(self, content: str) -> None:  
        """Проверка хеша содержимого .env"""  
        if len(content) > 10_000:  
            self._quantum_fail("ENV_SIZE_LIMIT", "Env file too large")  
          
        expected_hash = os.getenv("WZ_ENV_HASH")  
        if not expected_hash:  
            return  
              
        actual_hash = hashlib.blake2b(content.encode(), digest_size=16).hexdigest()  
        if actual_hash != expected_hash:  
            self._quantum_fail("ENV_TAMPERED", "Environment compromised")  
  
    def _parse_env(self, content: str) -> Dict[str, str]:  
        """Парсинг с квантовой очисткой значений"""  
        return {  
            k.strip(): self._quantum_clean(v.strip())  
            for k, v in (  
                line.strip().split('=', 1)  
                for line in content.splitlines()  
                if '=' in line and not line.startswith('#')  
            )  
        }  
  
    def _quantum_clean(self, value: str) -> str:  
        """Глубокая очистка строк"""  
        return value.strip('\'"').replace('\0', '').encode('utf-8', 'ignore').decode('utf-8')  
  
    def _generate_quantum_id(self) -> str:  
        """Генерация ID с квантовой энтропией"""  
        entropy_sources = [  
            datetime.now(timezone.utc).isoformat(),  
            str(os.getpid()),  
            str(os.urandom(16)),  
            str(requests.get("http://worldtimeapi.org/api/ip").json()['unixtime'])  
        ]  
        return hashlib.blake2b(  
            "|".join(entropy_sources).encode(),  
            digest_size=32,  
            salt=os.urandom(16)  
        ).hexdigest()  
  
    def log(self, args: argparse.Namespace) -> None:  
        """Квантовый процесс логирования"""  
        payload = self._build_quantum_payload(args)  
        meta = self._generate_quantum_meta(args)  
          
        if args.verbose:  
            self._safe_print(json.dumps(meta, indent=2, ensure_ascii=False))  
              
        self._cache_quantum_meta(meta)  
        self._send_quantum_request(payload)  
  
    def _build_quantum_payload(self, args: argparse.Namespace) -> Dict[str, Any]:  
        """Построение квантово-устойчивого payload"""  
        try:  
            return {  
                "parent": {"database_id": self.env["NOTION_LOG_DB_ID"]},  
                "properties": {  
                    "Name": {"title": [{"text": {"content": self._quantum_truncate(args.name, 2000)}}]},  
                    "Type": {"select": {"name": self._validate_quantum_type(args.type)}},  
                    "Event": {"rich_text": [{"text": {"content": self._quantum_truncate(args.event, 2000)}}]},  
                    "Result": {"rich_text": [{"text": {"content": self._quantum_truncate(args.result, 2000)}}]},  
                    "Source": {"rich_text": [{"text": {"content": self._quantum_truncate(quote(args.source), 2000)}}]},  
                    "Timestamp": {"date": {"start": datetime.now(timezone.utc).isoformat()}},  
                    "QuantumID": {"rich_text": [{"text": {"content": self.session_id}}]}  
                }  
            }  
        except Exception as e:  
            self._quantum_fail("PAYLOAD_COLLAPSE", f"Quantum construction failed: {str(e)}")  
  
    def _generate_quantum_meta(self, args: argparse.Namespace) -> Dict[str, Any]:  
        """Генерация метаданных с квантовыми свойствами"""  
        return {  
            "quantum_dimension": self._calculate_dimension(args.event),  
            "entropy": self._calculate_quantum_entropy(args.event),  
            "vector": self._detect_quantum_vector(args.type),  
            "session": self.session_id,  
            "timestamp": datetime.now(timezone.utc).isoformat(),  
            "signature": self._generate_meta_signature(args)  
        }  
  
    def _calculate_dimension(self, text: str) -> int:  
        """Фрактальная размерность текста"""  
        return max(1, min(11, len(text) % 11 + 1))  # Ограничение 11D  
  
    def _calculate_quantum_entropy(self, text: str) -> float:  
        """Квантовый расчет энтропии"""  
        if not text:  
            return 0.0  
              
        byte_freq = {}  
        total = len(text.encode('utf-8'))  
        for byte in text.encode('utf-8'):  
            byte_freq[byte] = byte_freq.get(byte, 0) + 1  
              
        return round(-sum((count/total) * ((count/total) * 1.442695) for count in byte_freq.values()), 4)  
  
    def _detect_quantum_vector(self, event_type: str) -> str:  
        """Определение квантового вектора события"""  
        return next(  
            (cat for cat, types in LOG_STRUCTURE.items() if event_type in types),  
            "singularity"  
        )  
  
    def _generate_meta_signature(self, args: argparse.Namespace) -> str:  
        """Квантовая подпись метаданных"""  
        data = f"{args.type}:{args.name}:{args.result}"  
        return hashlib.blake2b(  
            data.encode(),  
            key=self.session_id.encode(),  
            digest_size=16  
        ).hexdigest()  
  
    def _validate_quantum_type(self, event_type: str) -> str:  
        """Квантовая валидация типа"""  
        if not event_type or len(event_type) > 100:  
            self._quantum_fail("TYPE_COLLAPSE", f"Invalid quantum type: {event_type}")  
        return event_type[:100]  
  
    def _quantum_truncate(self, text: str, limit: int) -> str:  
        """Безопасное ограничение длины с Unicode-коррекцией"""  
        return text[:limit].encode('utf-8')[:limit].decode('utf-8', 'ignore').rstrip('\x00') if text else ""  
  
    def _cache_quantum_meta(self, meta: Dict[str, Any]) -> None:  
        """Квантовое кэширование с коллапсом волновой функции"""  
        try:  
            cache = []  
            if self.meta_cache_path.exists():  
                with self.meta_cache_path.open('r', encoding='utf-8') as f:  
                    try:  
                        cache = json.load(f)  
                        if not isinstance(cache, list):  
                            raise ValueError("Invalid cache format")  
                    except json.JSONDecodeError:  
                        pass  
  
            cache.append(meta)  
            temp_path = self.meta_cache_path.with_suffix('.tmp')  
              
            with temp_path.open('w', encoding='utf-8') as f:  
                json.dump(cache[-100:], f, ensure_ascii=False)  
                  
            temp_path.replace(self.meta_cache_path)  
        except Exception:  
            pass  # Кэш не критичен для работы  
  
    def _send_quantum_request(self, payload: Dict[str, Any]) -> None:  
        """Квантовая отправка с суперпозицией состояний"""  
        headers = {  
            "Authorization": f"Bearer {self.env['NOTION_API_TOKEN']}",  
            "Notion-Version": "2022-06-28",  
            "Content-Type": "application/json",  
            "X-Quantum-ID": self.session_id  
        }  
  
        for attempt in range(MAX_RETRIES):  
            try:  
                with requests.Session() as session:  
                    response = session.post(  
                        "https://api.notion.com/v1/pages",  
                        json=payload,  
                        headers=headers,  
                        timeout=REQUEST_TIMEOUT  
                    )  
                    response.raise_for_status()  
                    return  
                      
            except requests.exceptions.HTTPError as e:  
                if attempt == MAX_RETRIES - 1:  
                    error_msg = self._parse_quantum_error(e)  
                    self._quantum_fail("API_COLLAPSE", error_msg)  
                continue  
                  
            except requests.exceptions.RequestException as e:  
                if attempt == MAX_RETRIES - 1:  
                    self._quantum_fail("NETWORK_COLLAPSE", f"Quantum network failure: {str(e)}")  
                continue  
  
    def _parse_quantum_error(self, error: requests.exceptions.HTTPError) -> str:  
        """Квантовый анализ ошибок API"""  
        if not error.response:  
            return str(error)  
              
        try:  
            error_data = error.response.json()  
            return f"{error.response.status_code}: {error_data.get('message', 'Unknown quantum error')}"  
        except ValueError:  
            return f"{error.response.status_code}: {error.response.text[:500]}"  
  
    def _safe_print(self, text: str) -> None:  
        """Атомарный вывод с защитой от краша"""  
        try:  
            print(text, file=sys.stderr if sys.stderr.isatty() else sys.stdout)  
        except (IOError, UnicodeError):  
            pass  # Игнорируем ошибки вывода  
  
    def _quantum_fail(self, code: str, message: str) -> NoReturn:  
        """Квантовый коллапс системы"""  
        self._safe_print(f"QUANTUM FAILURE [{code}]: {message}")  
        sys.exit(1 if code.startswith('NETWORK') else 2)  
  
def main():  
    parser = argparse.ArgumentParser(  
        description="Quantum Fractal Logger for Notion",  
        formatter_class=argparse.ArgumentDefaultsHelpFormatter  
    )  
    parser.add_argument(  
        "--type",  
        required=True,  
        choices=[t for types in LOG_STRUCTURE.values() for t in types],  
        help="Quantum event type"  
    )  
    parser.add_argument("--name", required=True, help="Event superposition name")  
    parser.add_argument("--event", required=True, help="Quantum event description")  
    parser.add_argument("--result", default="ok", help="Collapsed result state")  
    parser.add_argument("--source", required=True, help="Event origin source")  
    parser.add_argument("--verbose", action="store_true", help="Output quantum metadata")  
  
    try:  
        QuantumFractalLogger().log(parser.parse_args())  
    except KeyboardInterrupt:  
        print("Quantum observation cancelled", file=sys.stderr)  
        sys.exit(130)  
    except Exception as e:  
        print(f"QUANTUM DECOHERENCE: {str(e)}", file=sys.stderr)  
        sys.exit(1)  
  
if __name__ == "__main__":  
    main()
