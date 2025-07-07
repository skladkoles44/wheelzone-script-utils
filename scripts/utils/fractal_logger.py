#!/usr/bin/env python3  
"""  
Notion Logger CLI v3.0 — Фрактальная система логгирования WheelZone  
"""  
  
import os  
import sys  
import argparse  
import requests  
import hashlib  
from datetime import datetime, timezone  
from typing import Dict, Any, Tuple, NoReturn, Optional  
from pathlib import Path  
  
# Фрактальные константы системы  
LOG_STRUCTURE = {  
    "core": ["script-event", "ci-step", "alert"],  
    "meta": ["debug", "trace", "fractal"],  
    "quant": ["entropy", "vector", "state"]  
}  
  
class FractalLogger:  
    def __init__(self):  
        self.env_cache = self._load_fractal_env()  
        self.session_hash = self._generate_session_fractal()  
          
    def _load_fractal_env(self) -> Dict[str, str]:  
        """Загрузка окружения с фрактальной валидацией"""  
        env_path = Path("~/.env.wzbot").expanduser()  
        try:  
            with env_path.open('r', encoding='utf-8') as f:  
                return self._parse_fractal_env(f.read())  
        except Exception as e:  
            self._critical_fractal("ENV_LOAD", str(e))  
      
    def _parse_fractal_env(self, content: str) -> Dict[str, str]:  
        """Парсинг с фрактальной обработкой значений"""  
        return {  
            k: self._fractal_clean(v)   
            for k, v in (  
                line.strip().split('=', 1)   
                for line in content.splitlines()   
                if '=' in line and not line.startswith('#')  
            )  
        }  
      
    def _fractal_clean(self, value: str) -> str:  
        """Фрактальная очистка значений"""  
        return value.strip('\'"').encode('utf-8').decode('unicode-escape')  
      
    def _generate_session_fractal(self) -> str:  
        """Генерация фрактального идентификатора сессии"""  
        seed = f"{datetime.now(timezone.utc).isoformat()}{os.getpid()}"  
        return hashlib.blake2b(seed.encode(), digest_size=16).hexdigest()  
      
    def log(self, args: argparse.Namespace) -> None:  
        """Фрактальный процесс логгирования"""  
        payload = self._build_fractal_payload(args)  
        self._send_fractal_request(payload)  
      
    def _build_fractal_payload(self, args: argparse.Namespace) -> Dict[str, Any]:  
        """Построение фрактального payload"""  
        try:  
            return {  
                "parent": {"database_id": self.env_cache["NOTION_LOG_DB_ID"]},  
                "properties": self._generate_fractal_properties(args),  
                "fractal_meta": self._generate_fractal_meta(args)  
            }  
        except Exception as e:  
            self._critical_fractal("PAYLOAD_BUILD", str(e))  
      
    def _generate_fractal_properties(self, args: argparse.Namespace) -> Dict[str, Any]:  
        """Генерация фрактальных свойств"""  
        return {  
            "Name": {"title": [{"text": {"content": self._fractal_truncate(args.name, 2000)}}]},  
            "Type": {"select": {"name": self._validate_fractal_type(args.type)}},  
            "Event": {"rich_text": [{"text": {"content": self._fractal_truncate(args.event, 2000)}}]},  
            "Result": {"rich_text": [{"text": {"content": self._fractal_truncate(args.result, 2000)}}]},  
            "Source": {"rich_text": [{"text": {"content": self._fractal_truncate(args.source, 2000)}}]},  
            "Timestamp": {"date": {"start": datetime.now(timezone.utc).isoformat()}},  
            "FractalID": {"rich_text": [{"text": {"content": self.session_hash}}]}  
        }  
      
    def _generate_fractal_meta(self, args: argparse.Namespace) -> Dict[str, Any]:  
        """Генерация метаданных фрактала"""  
        return {  
            "dimensions": self._calculate_fractal_dimensions(args),  
            "entropy": self._calculate_entropy(args.event),  
            "vector": self._detect_event_vector(args.type)  
        }  
      
    def _calculate_fractal_dimensions(self, args: argparse.Namespace) -> int:  
        """Вычисление фрактальной размерности события"""  
        return len(args.event) % 8 + 1  # Простая фрактальная логика  
      
    def _calculate_entropy(self, text: str) -> float:  
        """Вычисление энтропии события"""  
        if not text:  
            return 0.0  
        entropy = 0.0  
        for x in range(256):  
            p_x = text.encode('utf-8').count(x) / len(text)  
            if p_x > 0:  
                entropy += -p_x * (p_x * 1.4426950408889634)  
        return round(entropy, 4)  
      
    def _detect_event_vector(self, event_type: str) -> str:  
        """Определение вектора события"""  
        for category, types in LOG_STRUCTURE.items():  
            if event_type in types:  
                return category  
        return "unknown"  
      
    def _validate_fractal_type(self, value: str) -> str:  
        """Фрактальная валидация типа"""  
        if not value or len(value) > 100:  
            self._critical_fractal("TYPE_VALIDATION", f"Invalid type: {value}")  
        return value  
      
    def _fractal_truncate(self, text: str, limit: int) -> str:  
        """Фрактальное ограничение длины"""  
        return text[:limit] if text else ""  
      
    def _send_fractal_request(self, payload: Dict[str, Any]) -> None:  
        """Отправка фрактального запроса"""  
        url = "https://api.notion.com/v1/pages"  
        headers = {  
            "Authorization": f"Bearer {self.env_cache['NOTION_API_TOKEN']}",  
            "Notion-Version": "2022-06-28",  
            "Content-Type": "application/json",  
            "X-Fractal-ID": self.session_hash  
        }  
          
        try:  
            response = requests.post(  
                url,  
                headers=headers,  
                json=payload,  
                timeout=(3.05, 10)  
            )  
            response.raise_for_status()  
        except requests.exceptions.HTTPError as e:  
            self._handle_fractal_error(e)  
        except Exception as e:  
            self._critical_fractal("NETWORK_FAILURE", str(e))  
      
    def _handle_fractal_error(self, error: requests.exceptions.HTTPError) -> NoReturn:  
        """Обработка фрактальных ошибок"""  
        error_msg = f"API Error: {str(error)}"  
        if error.response is not None:  
            try:  
                error_details = error.response.json()  
                error_msg += f"\nDetails: {error_details.get('message', 'No details')}"  
            except ValueError:  
                error_msg += f"\nResponse: {error.response.text[:500]}"  
        self._critical_fractal("API_FAILURE", error_msg)  
      
    def _critical_fractal(self, code: str, message: str) -> NoReturn:  
        """Критическая фрактальная ошибка"""  
        sys.stderr.write(f"FRACTAL ERROR [{code}]: {message}\n")  
        sys.exit(1)  
  
def main():  
    """Фрактальная точка входа"""  
    parser = argparse.ArgumentParser(  
        description="Fractal Logging System for WheelZone",  
        formatter_class=argparse.ArgumentDefaultsHelpFormatter  
    )  
    parser.add_argument(  
        "--type",  
        required=True,  
        choices=[t for types in LOG_STRUCTURE.values() for t in types],  
        help="Fractal event type"  
    )  
    parser.add_argument(  
        "--name",  
        required=True,  
        help="Event fractal identifier"  
    )  
    parser.add_argument(  
        "--event",  
        required=True,  
        help="Fractal event description"  
    )  
    parser.add_argument(  
        "--result",  
        default="ok",  
        help="Fractal result state"  
    )  
    parser.add_argument(  
        "--source",  
        required=True,  
        help="Fractal event source"  
    )  
      
    try:  
        fractal_logger = FractalLogger()  
        fractal_logger.log(parser.parse_args())  
    except KeyboardInterrupt:  
        sys.stderr.write("Fractal logging interrupted\n")  
        sys.exit(130)  
    except Exception as e:  
        sys.stderr.write(f"Fractal system failure: {str(e)}\n")  
        sys.exit(1)  
  
if __name__ == "__main__":  
    main()
