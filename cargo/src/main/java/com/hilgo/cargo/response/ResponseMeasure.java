package com.hilgo.cargo.response;
import com.hilgo.cargo.entity.enums.Size;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class ResponseMeasure {
	private Double weight;

	private Double height;	

	private Size size;
}
